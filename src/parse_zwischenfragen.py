from __future__ import annotations

import argparse
import csv
import joblib
import json
import re
from pathlib import Path
from typing import Any
from tqdm import tqdm

from bs4 import BeautifulSoup, Tag

REQUEST_PATTERN = re.compile(
    r"gestatten\s+sie.*(zwischenfrage|kurzintervention)|(zwischenfrage|kurzintervention).*(gestatten\s+sie)",
    re.IGNORECASE,
)

ALLOW_PATTERN = re.compile(r"^(ja|gern|gerne|selbstverstaendlich|selbstverständlich|natuerlich|natürlich|aber sehr gern|bitte)", re.IGNORECASE)
DECLINE_PATTERN = re.compile(r"^nein\b|zeit", re.IGNORECASE)

# Load the TD-IDF model
model = joblib.load("../model/zwischenfrage/german_tfidf_model.pkl")


def normalize_text(text: str) -> str:
    return re.sub(r"\s+", " ", text).strip()


def sp_text(sp: Tag) -> str:
    return normalize_text(" ".join(node.get_text(" ", strip=True) for node in sp.find_all(["p", "stage"])))


def sp_info(sp: Tag) -> dict[str, str | None]:
    return {
        "name": normalize_text(sp.get("name") or "") or None,
        "who": normalize_text(sp.get("who") or "") or None,
        "position": normalize_text(sp.get("role") or "") or None,
        "parliamentary_group": normalize_text(sp.get("parliamentary_group") or "") or None,
        "party": normalize_text(sp.get("party") or "") or None,
        "speaker_label": normalize_text((sp.find("speaker").get_text(" ", strip=True) if sp.find("speaker") else ""))
        or None,
    }


def is_presidency(sp: Tag) -> bool:
    return normalize_text(sp.get("role") or "").lower() == "presidency"


def is_request_by_presidency(sp: Tag) -> bool:
    if not is_presidency(sp):
        return False
    for p in sp.find_all("p"):
        if REQUEST_PATTERN.search(normalize_text(p.get_text(" ", strip=True))):
            return True
    return False


def is_allowed_answer(text: str) -> bool:
    lowered = normalize_text(text)
    if not lowered:
        return False
    if DECLINE_PATTERN.search(lowered):
        return False
    return bool(ALLOW_PATTERN.search(lowered))


def is_allowed_answer_td_idf(text: str) -> bool:
    lowered = normalize_text(text)[0:80]
    if not lowered:
        return False
    preds = model.predict([lowered,])
    return True if preds[0] == 1 else False



def extract_zwischenfragen(xml_path: Path) -> list[dict[str, Any]]:
    with xml_path.open("r", encoding="utf-8") as f:
        soup = BeautifulSoup(f, "xml")

    speeches = soup.find_all("sp")
    results: list[dict[str, Any]] = []

    for i, request_sp in enumerate(speeches):
        if not isinstance(request_sp, Tag) or not is_request_by_presidency(request_sp):
            continue

        # The active speaker is expected right before the presidency asks for permission.
        current_sp: Tag | None = None
        j = i - 1
        while j >= 0:
            prev_sp = speeches[j]
            if isinstance(prev_sp, Tag) and not is_presidency(prev_sp):
                current_sp = prev_sp
                break
            j -= 1

        if current_sp is None:
            continue

        # The first non-presidency turn after the request is usually the answer of the current speaker.
        answer_sp: Tag | None = None
        k = i + 1
        while k < len(speeches):
            candidate = speeches[k]
            if isinstance(candidate, Tag) and not is_presidency(candidate):
                answer_sp = candidate
                break
            k += 1

        if answer_sp is None:
            continue

        if normalize_text(answer_sp.get("who") or "") != normalize_text(current_sp.get("who") or ""):
            continue

        answer_text = sp_text(answer_sp)
        # permission_granted = is_allowed_answer(answer_text)
        permission_granted = is_allowed_answer_td_idf(answer_text)

        # The interruptor is the next non-presidency speaker that is not the current speaker.
        interruptor_sp: Tag | None = None
        m = k + 1
        while m < len(speeches):
            candidate = speeches[m]
            if not isinstance(candidate, Tag):
                m += 1
                continue
            if is_presidency(candidate):
                m += 1
                continue
            if normalize_text(candidate.get("who") or "") == normalize_text(current_sp.get("who") or ""):
                m += 1
                continue
            interruptor_sp = candidate
            break

        if interruptor_sp is None:
            continue

        question_text = ""
        if permission_granted:
            question_text = normalize_text(
                "\n".join(normalize_text(p.get_text(" ", strip=True)) for p in interruptor_sp.find_all("p"))
            )
            if not question_text:
                continue

        results.append(
            {
                "current_speaker": sp_info(current_sp),
                "interruptor": sp_info(interruptor_sp),
                "zwischenfrage_text": question_text,
                "permission_request": sp_text(request_sp),
                "permission_answer": answer_text,
                "permission_granted": permission_granted,
            }
        )

    return results


def collect_xml_files(input_path: Path) -> list[Path]:
    if input_path.is_file():
        return [input_path]
    if input_path.is_dir():
        return sorted(p for p in input_path.rglob("*.xml") if p.is_file())
    raise FileNotFoundError(f"Input path does not exist: {input_path}")


def extract_zwischenfragen_from_path(input_path: Path) -> list[dict[str, Any]]:
    all_items: list[dict[str, Any]] = []
    xml_files = collect_xml_files(input_path)
    for xml_file in tqdm(xml_files):
        file_items = extract_zwischenfragen(xml_file)
        for item in file_items:
            all_items.append({"source_file": xml_file.name, **item})
    return all_items


def flatten_for_csv(item: dict[str, Any]) -> dict[str, str]:
    current = item.get("current_speaker", {})
    interruptor = item.get("interruptor", {})
    return {
        "source_file": str(item.get("source_file") or ""),
        "permission_request": str(item.get("permission_request") or ""),
        "permission_answer": str(item.get("permission_answer") or ""),
        "permission_granted": str(item.get("permission_granted") or ""),
        "zwischenfrage_text": str(item.get("zwischenfrage_text") or ""),
        "current_name": str(current.get("name") or ""),
        "current_who": str(current.get("who") or ""),
        "current_position": str(current.get("position") or ""),
        "current_parliamentary_group": str(current.get("parliamentary_group") or ""),
        "current_party": str(current.get("party") or ""),
        "current_speaker_label": str(current.get("speaker_label") or ""),
        "interruptor_name": str(interruptor.get("name") or ""),
        "interruptor_who": str(interruptor.get("who") or ""),
        "interruptor_position": str(interruptor.get("position") or ""),
        "interruptor_parliamentary_group": str(interruptor.get("parliamentary_group") or ""),
        "interruptor_party": str(interruptor.get("party") or ""),
        "interruptor_speaker_label": str(interruptor.get("speaker_label") or ""),
    }


def write_csv(items: list[dict[str, Any]], output_path: Path) -> None:
    rows = [flatten_for_csv(item) for item in items]
    fieldnames = [
        "source_file",
        "permission_request",
        "permission_answer",
        "permission_granted",
        "zwischenfrage_text",
        "current_name",
        "current_who",
        "current_position",
        "current_parliamentary_group",
        "current_party",
        "current_speaker_label",
        "interruptor_name",
        "interruptor_who",
        "interruptor_position",
        "interruptor_parliamentary_group",
        "interruptor_party",
        "interruptor_speaker_label",
    ]

    with output_path.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def main() -> None:
    parser = argparse.ArgumentParser(description="Extract allowed Zwischenfragen from Bundestag XML transcripts.")
    parser.add_argument("input_path", type=Path, help="Path to a TEI XML file or directory of XML files")
    parser.add_argument("-o", "--output", type=Path, help="Optional output path")
    parser.add_argument("--format", choices=["json", "csv"], default="json", help="Output format")
    args = parser.parse_args()

    items = extract_zwischenfragen_from_path(args.input_path)

    if args.output:
        if args.format == "csv":
            write_csv(items, args.output)
        else:
            args.output.write_text(json.dumps(items, ensure_ascii=False, indent=2), encoding="utf-8")
    else:
        print(json.dumps(items, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()