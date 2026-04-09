from __future__ import annotations

import argparse
import csv
import re
from collections import defaultdict
from pathlib import Path
from typing import Iterator
from xml.etree import ElementTree as ET


def clean_text(value: str | None) -> str:
	if value is None:
		return ""
	return re.sub(r"\s+", " ", value).strip()


def get_child_text(parent: ET.Element, path: str) -> str:
	node = parent.find(path)
	if node is None:
		return ""
	return clean_text(node.text)


def normalize_gender(gender_raw: str) -> str:
	value = clean_text(gender_raw).lower()
	value = value.replace("ä", "ae").replace("ö", "oe").replace("ü", "ue")
	if value in {"m", "maennlich", "mann", "male"}:
		return "male"
	if value in {"w", "weiblich", "frau", "female"}:
		return "female"
	if value in {"divers", "diverse", "non-binary", "nonbinary"}:
		return "diverse"
	return "unknown"


def select_primary_name(mdb: ET.Element) -> ET.Element | None:
	names = mdb.findall("NAMEN/NAME")
	if not names:
		return None

	# Prefer the active/current name entry if present.
	for name in names:
		history_to = get_child_text(name, "HISTORIE_BIS")
		if history_to == "":
			return name

	# Fallback to the first available historical name.
	return names[0]


def build_full_name(name: ET.Element) -> str:
	first_name = get_child_text(name, "VORNAME")
	prefix = get_child_text(name, "PRAEFIX")
	nobility = get_child_text(name, "ADEL")
	last_name = get_child_text(name, "NACHNAME")
	place_suffix = get_child_text(name, "ORTSZUSATZ")

	parts = [first_name, prefix, nobility, last_name]
	base_name = " ".join(part for part in parts if part)
	if place_suffix:
		return f"{base_name} ({place_suffix})"
	return base_name


def iter_name_gender_pairs(xml_path: Path) -> Iterator[tuple[str, str]]:
	context = ET.iterparse(xml_path, events=("end",))
	for _, elem in context:
		if elem.tag != "MDB":
			continue

		name_node = select_primary_name(elem)
		if name_node is None:
			elem.clear()
			continue

		full_name = build_full_name(name_node)
		gender_raw = get_child_text(elem, "BIOGRAFISCHE_ANGABEN/GESCHLECHT")
		normalized_gender = normalize_gender(gender_raw)

		if full_name:
			yield full_name, normalized_gender

		elem.clear()


def build_lookup_table(xml_path: Path) -> list[dict[str, str]]:
	genders_by_name: dict[str, set[str]] = defaultdict(set)
	for full_name, gender in iter_name_gender_pairs(xml_path):
		genders_by_name[full_name].add(gender)

	rows: list[dict[str, str]] = []
	for full_name in sorted(genders_by_name):
		gender_set = genders_by_name[full_name] - {"unknown"}
		if len(gender_set) == 1:
			resolved_gender = next(iter(gender_set))
		elif len(gender_set) == 0:
			resolved_gender = "unknown"
		else:
			# If one name maps to multiple genders across entries, mark as unknown.
			resolved_gender = "unknown"
		rows.append({"full_name": full_name, "gender": resolved_gender})

	return rows


def write_lookup_csv(rows: list[dict[str, str]], output_path: Path) -> None:
	output_path.parent.mkdir(parents=True, exist_ok=True)
	with output_path.open("w", encoding="utf-8", newline="") as handle:
		writer = csv.DictWriter(handle, fieldnames=["full_name", "gender"])
		writer.writeheader()
		writer.writerows(rows)


def main() -> None:
	parser = argparse.ArgumentParser(
		description="Build a lookup table mapping each Bundestag member full name to gender."
	)
	parser.add_argument(
		"input_xml",
		type=Path,
		help="Path to MDB_STAMMDATEN.XML",
	)
	parser.add_argument(
		"-o",
		"--output",
		type=Path,
		default=Path("data/member_gender_lookup.csv"),
		help="Output CSV path (default: data/member_gender_lookup.csv)",
	)
	args = parser.parse_args()

	rows = build_lookup_table(args.input_xml)
	write_lookup_csv(rows, args.output)
	print(f"Wrote {len(rows)} entries to {args.output}")


if __name__ == "__main__":
	main()
