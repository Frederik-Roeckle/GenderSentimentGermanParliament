from __future__ import annotations

import argparse
import re
from pathlib import Path

import pandas as pd
import spacy


NAME_TOKEN = "[NAME]"

SALUTATION_PATTERN = re.compile(
    r"\b("
    r"Herr|Frau|Fräulein|"
    r"Kolleg(?:e|in|en|innen)|"
    r"Abgeordnete(?:r|n|m)?|"
    r"Liebe|Lieber|Geehrte|Geehrter"
    r")\b\s*",
    flags=re.IGNORECASE,
)

SALUTATION_PHRASE_PATTERN = re.compile(
    r"\b(?:Herr|Frau|Fräulein|Kolleg(?:e|in|en|innen)|Abgeordnete(?:r|n|m)?|Liebe|Lieber|Geehrte|Geehrter)\b"
    r"(?:\s+(?:Herr|Frau|Fräulein|Kolleg(?:e|in|en|innen)|Abgeordnete(?:r|n|m)?|Liebe|Lieber|Geehrte|Geehrter))?"
    r"(?:\s+(?:Dr\.?|Prof\.?))?"
    r"(?:\s+(?:von|vom|van|zu|zur|de|del|der|den))?"
    r"(?:\s+[A-ZÄÖÜ][a-zA-ZÄÖÜäöüß\-]+){0,4}",
    flags=re.IGNORECASE,
)

PERSON_LABELS = {"PER", "PERSON"}


def normalize_spaces(value: str) -> str:
	return re.sub(r"\s+", " ", value).strip()


def clean_name_for_regex(name: str) -> str:
	cleaned = normalize_spaces(name)
	cleaned = re.sub(r"\([^)]*\)", "", cleaned)
	cleaned = normalize_spaces(cleaned)
	return cleaned


def is_likely_full_name(name: str) -> bool:
	parts = [p for p in name.split(" ") if p]
	if len(parts) < 2:
		return False
	if len(name) < 5:
		return False
	return True


def build_name_regex(df: pd.DataFrame) -> re.Pattern[str] | None:
	candidate_columns = [
		"current_name",
		"interruptor_name",
		"current_who",
		"interruptor_who",
	]

	names: set[str] = set()
	for col in candidate_columns:
		if col not in df.columns:
			continue
		series = df[col].dropna().astype(str)
		for raw_name in series:
			cleaned = clean_name_for_regex(raw_name)
			if is_likely_full_name(cleaned):
				names.add(cleaned)

	if not names:
		return None

	escaped = sorted((re.escape(name) for name in names), key=len, reverse=True)
	pattern = r"\b(?:" + "|".join(escaped) + r")\b"
	return re.compile(pattern)


def mask_salutation_phrases(text: str) -> str:
	masked = SALUTATION_PHRASE_PATTERN.sub(NAME_TOKEN, text)
	masked = SALUTATION_PATTERN.sub(f"{NAME_TOKEN} ", masked)
	return masked


def collapse_repeated_name_tokens(text: str) -> str:
	text = re.sub(r"(?:\[NAME\]\s*){2,}", f"{NAME_TOKEN} ", text)
	return re.sub(r"\s+", " ", text).strip()


def mask_with_regex(text: str, name_pattern: re.Pattern[str] | None) -> str:
	# Prioritize salutations so forms such as "Herr"/"Frau"/"Kollege" are masked even
	# when a full person name is not detected.
	masked = mask_salutation_phrases(text)
	if name_pattern is not None:
		masked = name_pattern.sub(NAME_TOKEN, masked)
	return collapse_repeated_name_tokens(masked)


def mask_with_ner(text: str, nlp: spacy.language.Language) -> str:
	pre_masked = mask_salutation_phrases(text)
	doc = nlp(pre_masked)
	pieces: list[str] = []
	cursor = 0

	for ent in doc.ents:
		if ent.label_ not in PERSON_LABELS:
			continue
		if ent.start_char < cursor:
			continue
		pieces.append(pre_masked[cursor:ent.start_char])
		pieces.append(NAME_TOKEN)
		cursor = ent.end_char

	pieces.append(pre_masked[cursor:])
	return collapse_repeated_name_tokens("".join(pieces))


def load_german_pipeline(model_name: str) -> spacy.language.Language:
	try:
		return spacy.load(model_name)
	except OSError as exc:
		raise RuntimeError(
			"Could not load spaCy model '"
			f"{model_name}'. Install one of: de_core_news_sm, de_core_news_md, de_core_news_lg"
		) from exc


def main() -> None:
	parser = argparse.ArgumentParser(
		description="Mask gender-identifying titles and names in zwischenfrage_text using regex and spaCy NER."
	)
	parser.add_argument(
		"-i",
		"--input",
		type=Path,
		default=Path("./output_gender.csv"),
		help="Input CSV path (default: src/output_gender.csv)",
	)
	parser.add_argument(
		"-o",
		"--output",
		type=Path,
		default=Path("./output_gender_masked.csv"),
		help="Output CSV path (default: src/output_gender_masked.csv)",
	)
	parser.add_argument(
		"--text-column",
		default="zwischenfrage_text",
		help="Column to mask (default: zwischenfrage_text)",
	)
	parser.add_argument(
		"--spacy-model",
		default="de_core_news_lg",
		help="German spaCy model name (default: de_core_news_lg)",
	)
	args = parser.parse_args()

	df = pd.read_csv(args.input)
	if args.text_column not in df.columns:
		raise ValueError(
			f"Column '{args.text_column}' not found in input CSV. Available columns: {list(df.columns)}"
		)

	df[args.text_column] = df[args.text_column].fillna("").astype(str)

	name_pattern = build_name_regex(df)
	nlp = load_german_pipeline(args.spacy_model)

	regex_col = f"{args.text_column}_masked_regex"
	ner_col = f"{args.text_column}_masked_ner"
	combined_col = f"{args.text_column}_masked_combined"

	df[regex_col] = df[args.text_column].apply(lambda text: mask_with_regex(text, name_pattern))
	df[ner_col] = df[args.text_column].apply(lambda text: mask_with_ner(text, nlp))
	df[combined_col] = df[regex_col].apply(lambda text: mask_with_ner(text, nlp))

	args.output.parent.mkdir(parents=True, exist_ok=True)
	df.to_csv(args.output, index=False)

	print(f"Read {len(df)} rows from {args.input}")
	print(f"Wrote masked output to {args.output}")
	print(f"Added columns: {regex_col}, {ner_col}, {combined_col}")


if __name__ == "__main__":
	main()
