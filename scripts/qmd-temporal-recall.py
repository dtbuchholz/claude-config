#!/usr/bin/env python3
"""Date-scoped recall helper for QMD conversation collections."""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from dataclasses import dataclass
from datetime import date, datetime, timedelta
from typing import Iterable


QMD_BIN = str(Path.home() / ".claude/scripts/qmd.sh")
WEEKDAYS = {
    "monday": 0,
    "tuesday": 1,
    "wednesday": 2,
    "thursday": 3,
    "friday": 4,
    "saturday": 5,
    "sunday": 6,
}


@dataclass
class Hit:
    score: float
    path: str
    rank_score: float


def normalize_date_phrase(phrase: str, today: date | None = None) -> str:
    today = today or datetime.now().date()
    raw = phrase.strip().lower()

    if re.fullmatch(r"\d{4}-\d{2}-\d{2}", raw):
        return raw
    if raw == "today":
        return today.isoformat()
    if raw == "yesterday":
        return (today - timedelta(days=1)).isoformat()

    m_last = re.fullmatch(r"last\s+([a-z]+)", raw)
    if m_last and m_last.group(1) in WEEKDAYS:
        target = WEEKDAYS[m_last.group(1)]
        delta = (today.weekday() - target) % 7
        if delta == 0:
            delta = 7
        return (today - timedelta(days=delta)).isoformat()

    if raw in WEEKDAYS:
        target = WEEKDAYS[raw]
        delta = (today.weekday() - target) % 7
        if delta == 0:
            delta = 7
        return (today - timedelta(days=delta)).isoformat()

    raise ValueError(
        f"Unsupported date phrase: {phrase!r}. Use YYYY-MM-DD, today, yesterday, or 'last Tuesday'."
    )


def list_collection_paths(collection: str) -> list[str]:
    cmd = [QMD_BIN, "ls", collection]
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0:
        raise RuntimeError(f"qmd ls failed for {collection}: {proc.stderr.strip()}")
    paths: list[str] = []
    for line in proc.stdout.splitlines():
        match = re.search(r"(qmd://\S+)$", line.strip())
        if match:
            paths.append(match.group(1))
    return paths


def date_in_path(path: str, day: str) -> bool:
    return path.endswith(f"-{day}.md")


def keyword_overlap(query: str, text: str) -> int:
    tokens = [t for t in re.findall(r"[a-zA-Z0-9]+", query.lower()) if len(t) >= 4]
    if not tokens:
        return 0
    hay = text.lower()
    return sum(1 for tok in set(tokens) if tok in hay)


def rank_hits(query: str, hits: Iterable[Hit]) -> list[Hit]:
    ranked: list[Hit] = []
    for h in hits:
        overlap = keyword_overlap(query, h.path)
        h.rank_score = h.score + (0.1 * overlap)
        ranked.append(h)
    ranked.sort(key=lambda x: x.rank_score, reverse=True)
    return ranked


def qmd_get(path: str, lines: int = 260) -> str:
    cmd = [QMD_BIN, "get", path, "-l", str(lines)]
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0:
        return ""
    return proc.stdout


def extract_dialogue_blocks(text: str) -> list[tuple[str, str]]:
    blocks: list[tuple[str, str]] = []
    current_header = ""
    current_body: list[str] = []
    for raw in text.splitlines():
        line = raw.rstrip()
        if line.startswith("### ["):
            if current_header and current_body:
                blocks.append((current_header, "\n".join(current_body).strip()))
            current_header = line
            current_body = []
            continue
        if current_header:
            if line.startswith("## "):
                if current_header and current_body:
                    blocks.append((current_header, "\n".join(current_body).strip()))
                current_header = ""
                current_body = []
                continue
            if line == "":
                if current_body:
                    blocks.append((current_header, "\n".join(current_body).strip()))
                    current_header = ""
                    current_body = []
                continue
            current_body.append(line)
    if current_header and current_body:
        blocks.append((current_header, "\n".join(current_body).strip()))
    return blocks


def best_excerpt(doc: str, question: str, max_blocks: int = 3) -> list[tuple[str, str]]:
    blocks = extract_dialogue_blocks(doc)
    if not blocks:
        return []
    scored = []
    for header, body in blocks:
        score = keyword_overlap(question, f"{header}\n{body}")
        scored.append((score, header, body))
    scored.sort(key=lambda x: x[0], reverse=True)
    strong = [(h, b) for s, h, b in scored if s > 0][:max_blocks]
    if strong:
        return strong
    return [(h, b) for _, h, b in scored[:max_blocks]]


def main() -> int:
    parser = argparse.ArgumentParser(description="Date-scoped QMD recall helper.")
    parser.add_argument("date_phrase", help="Date phrase: YYYY-MM-DD, today, yesterday, or last Tuesday")
    parser.add_argument("question", help="Question to match against date-scoped conversations")
    parser.add_argument("--source", choices=["codex", "claude", "both"], default="both")
    parser.add_argument("--top", type=int, default=5, help="Max number of session docs to return")
    args = parser.parse_args()

    try:
        day = normalize_date_phrase(args.date_phrase)
    except ValueError as e:
        print(f"Error: {e}", file=sys.stderr)
        return 2

    collections = []
    if args.source in ("codex", "both"):
        collections.append("codex-conversations")
    if args.source in ("claude", "both"):
        collections.append("claude-conversations")

    hits: list[Hit] = []
    for collection in collections:
        for path in list_collection_paths(collection):
            if not date_in_path(path, day):
                continue
            doc = qmd_get(path, 320)
            overlap = keyword_overlap(args.question, doc)
            if overlap == 0 and args.question.strip().lower() not in ("what did i do?", "what did i do", "summary"):
                continue
            hits.append(Hit(score=float(overlap), path=path, rank_score=float(overlap)))

    ranked = rank_hits(args.question, hits)[: args.top]

    print(f"Date: {day}")
    print(f"Collections: {', '.join(collections)}")
    print(f"Matches: {len(hits)}")
    print("")

    if not ranked:
        print("No date-scoped matches found.")
        return 0

    for idx, hit in enumerate(ranked, start=1):
        print(f"{idx}. {hit.path} (score={hit.rank_score:.2f})")
        doc = qmd_get(hit.path, 360)
        excerpts = best_excerpt(doc, args.question, max_blocks=3)
        for header, body in excerpts:
            print(f"   {header}")
            for line in body.splitlines()[:5]:
                print(f"   {line}")
        print("")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
