#!/usr/bin/env python3
"""Date-scoped recall helper for QMD conversation collections.

Usage examples:
  qmd-temporal-recall.py "yesterday" "where did we leave off" --source both
  qmd-temporal-recall.py "2026-03-25" "qmd setup" --source claude --repo myrepo
  qmd-temporal-recall.py "last Tuesday" "summary" --json --top 8
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from dataclasses import dataclass, field
from datetime import date, datetime, timedelta
from typing import Iterable

QMD_BIN = "qmd"

# Queries that should return all date-scoped docs without keyword filtering
CATCH_ALL_QUERIES = frozenset({
    "where did we leave off",
    "where did we leave off?",
    "what did i do",
    "what did i do?",
    "summary",
    "catch me up",
    "what happened",
    "what happened?",
})

WEEKDAYS = {
    "monday": 0, "tuesday": 1, "wednesday": 2, "thursday": 3,
    "friday": 4, "saturday": 5, "sunday": 6,
}


@dataclass
class Hit:
    docid: str
    score: float
    path: str
    collection: str
    rank_score: float = 0.0
    is_subagent: bool = False
    excerpts: list[dict[str, str]] = field(default_factory=list)


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
        f"Unsupported date phrase: {phrase!r}. "
        "Use YYYY-MM-DD, today, yesterday, or 'last Tuesday'."
    )


def _run(cmd: list[str], **kwargs) -> subprocess.CompletedProcess:
    try:
        return subprocess.run(cmd, capture_output=True, text=True, **kwargs)
    except FileNotFoundError as exc:
        raise RuntimeError(
            "qmd CLI not found in PATH. Install QMD and retry."
        ) from exc


def list_collection_paths(collection: str) -> list[str]:
    proc = _run([QMD_BIN, "ls", collection])
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


def docid_from_path(path: str) -> str:
    name = path.rsplit("/", 1)[-1]
    return name.rsplit(".", 1)[0]


def is_subagent_path(path: str) -> bool:
    lower = path.lower()
    return "/subagents/" in lower or re.search(r"/agent-[^/]*\.md$", lower) is not None


def keyword_overlap(query: str, text: str) -> int:
    tokens = [t for t in re.findall(r"[a-zA-Z0-9]+", query.lower()) if len(t) >= 4]
    if not tokens:
        return 0
    hay = text.lower()
    return sum(1 for tok in set(tokens) if tok in hay)


def qmd_get(path: str, lines: int = 280) -> str:
    proc = _run([QMD_BIN, "get", path, "-l", str(lines)])
    if proc.returncode != 0:
        return ""
    return proc.stdout


# --- Excerpt extraction: structured sections first, dialogue blocks fallback ---

def extract_section_bullets(text: str) -> dict[str, list[str]]:
    """Extract from structured transcript sections (Goals, Actions, etc.)."""
    wanted = {
        "### Goals": [],
        "### Actions": [],
        "### Decisions": [],
        "### Issues And Risks": [],
        "## Final Turn Context": [],
    }
    current: str | None = None
    for raw in text.splitlines():
        line = raw.rstrip()
        if line in wanted:
            current = line
            continue
        if line.startswith("#"):
            current = None
            continue
        if current and line.startswith("- "):
            wanted[current].append(line[2:].strip())
    return wanted


def extract_dialogue_blocks(text: str) -> list[tuple[str, str]]:
    """Extract ### [HH:MM] user/assistant dialogue blocks."""
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
                if current_body:
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


def best_excerpts(doc: str, question: str, max_items: int = 3) -> list[dict[str, str]]:
    """Try structured sections first; fall back to dialogue blocks."""
    # Strategy 1: structured sections
    sections = extract_section_bullets(doc)
    items: list[dict[str, str]] = []
    for label in ("### Goals", "### Actions", "### Decisions",
                   "### Issues And Risks", "## Final Turn Context"):
        bullets = sections[label]
        if bullets:
            clean_label = label.replace("#", "").strip()
            for b in bullets[:2]:
                items.append({"section": clean_label, "text": b})
    if items:
        return items[:max_items]

    # Strategy 2: dialogue blocks scored by keyword overlap
    blocks = extract_dialogue_blocks(doc)
    if not blocks:
        return []
    scored = []
    for header, body in blocks:
        score = keyword_overlap(question, f"{header}\n{body}")
        scored.append((score, header, body))
    scored.sort(key=lambda x: x[0], reverse=True)
    results = scored[:max_items]
    return [
        {"section": h, "text": b[:200]}
        for _, h, b in results
    ]


# --- Deduplication ---

def dedup_hits(hits: list[Hit]) -> list[Hit]:
    """Remove subagent hits when a parent thread for the same session exists."""
    parent_keys: set[str] = set()
    parents: list[Hit] = []
    subagents: list[Hit] = []

    for h in hits:
        if h.is_subagent:
            subagents.append(h)
        else:
            parents.append(h)
            parent_keys.add(session_key_from_path(h.path))

    # Keep subagent only if no parent exists for the same session directory.
    kept_subs: list[Hit] = []
    for sub in subagents:
        has_parent = session_key_from_path(sub.path) in parent_keys
        if not has_parent:
            kept_subs.append(sub)

    return parents + kept_subs


# --- Repo filtering ---

def normalize_repo_name(value: str) -> str:
    token = value.strip().strip("/")
    if not token:
        return token
    return os.path.basename(token).lower()


def extract_cwd_paths(doc_text: str) -> list[str]:
    paths: list[str] = []
    # XML-like cwd marker used in captured environment context.
    paths.extend(m.strip() for m in re.findall(r"<cwd>([^<\n]+)</cwd>", doc_text, flags=re.IGNORECASE))
    # Fallback for plain-text markers.
    paths.extend(m.strip() for m in re.findall(r"(?im)^\s*cwd:\s*(\S+)\s*$", doc_text))
    return [p for p in paths if p]


def session_key_from_path(path: str) -> str:
    # qmd://collection/.../session/file.md => key: collection/.../session
    parts = path.split("://", 1)[-1].split("/")
    if len(parts) < 2:
        return path
    if "subagents" in parts:
        idx = parts.index("subagents")
        return "/".join(parts[:idx])
    dir_key = "/".join(parts[:-1])
    filename = parts[-1].rsplit(".", 1)[0]
    base = re.sub(r"-\d{4}-\d{2}-\d{2}$", "", filename)
    return f"{dir_key}/{base}"


def matches_repo(doc_text: str, repo_name: str) -> bool:
    """Check if transcript text references the given repo."""
    repo = normalize_repo_name(repo_name)
    if not repo:
        return False

    cwd_paths = extract_cwd_paths(doc_text)
    for cwd in cwd_paths:
        norm = cwd.rstrip("/")
        if os.path.basename(norm).lower() == repo:
            return True
        if f"/{repo}/" in norm.lower():
            return True

    # Weak fallback if no explicit cwd markers were extracted.
    if not cwd_paths:
        return re.search(rf"(?<![a-z0-9._-]){re.escape(repo)}(?![a-z0-9._-])", doc_text.lower()) is not None
    return False


def detect_repo_name() -> str | None:
    """Detect current repo name from git or cwd."""
    try:
        proc = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            capture_output=True, text=True, timeout=5,
        )
        if proc.returncode == 0:
            return os.path.basename(proc.stdout.strip())
    except (FileNotFoundError, subprocess.TimeoutExpired):
        pass
    return os.path.basename(os.getcwd())


# --- Ranking ---

def rank_hits(query: str, hits: Iterable[Hit]) -> list[Hit]:
    ranked: list[Hit] = []
    for h in hits:
        h.rank_score = h.score
        # Deprioritize subagent threads slightly
        if h.is_subagent:
            h.rank_score *= 0.8
        ranked.append(h)
    ranked.sort(key=lambda x: x.rank_score, reverse=True)
    return ranked


# --- Main ---

def main() -> int:
    parser = argparse.ArgumentParser(description="Date-scoped QMD recall helper.")
    parser.add_argument("date_phrase", help="YYYY-MM-DD, today, yesterday, or 'last Tuesday'")
    parser.add_argument("question", help="Question to match against conversations")
    parser.add_argument("--source", choices=["codex", "claude", "both"], default="both")
    parser.add_argument("--top", type=int, default=6, help="Max sessions to return")
    parser.add_argument("--repo", type=str, default=None,
                        help="Filter to threads mentioning this repo. "
                             "Use 'auto' to detect from cwd.")
    parser.add_argument("--json", dest="json_output", action="store_true",
                        help="Output structured JSON instead of text")
    args = parser.parse_args()

    try:
        day = normalize_date_phrase(args.date_phrase)
    except ValueError as e:
        print(f"Error: {e}", file=sys.stderr)
        return 2

    # Resolve repo filter
    repo_filter: str | None = None
    if args.repo == "auto":
        detected = detect_repo_name()
        repo_filter = normalize_repo_name(detected) if detected else None
    elif args.repo:
        repo_filter = normalize_repo_name(args.repo)

    is_catch_all = args.question.strip().lower() in CATCH_ALL_QUERIES

    collections = []
    if args.source in ("codex", "both"):
        collections.append("codex-conversations")
    if args.source in ("claude", "both"):
        collections.append("claude-conversations")

    all_hits: list[Hit] = []
    for collection in collections:
        try:
            paths = list_collection_paths(collection)
        except RuntimeError as e:
            print(f"Warning: {e}", file=sys.stderr)
            continue
        for path in paths:
            if not date_in_path(path, day):
                continue
            doc = qmd_get(path)
            if not doc:
                continue

            # Repo filter
            if repo_filter and not matches_repo(doc, repo_filter):
                continue

            overlap = keyword_overlap(args.question, doc)
            if overlap == 0 and not is_catch_all:
                continue

            all_hits.append(Hit(
                docid=docid_from_path(path),
                score=float(overlap),
                path=path,
                collection=collection,
                is_subagent=is_subagent_path(path),
            ))

    deduped = dedup_hits(all_hits)
    ranked = rank_hits(args.question, deduped)[:args.top]

    # Attach excerpts to top hits
    for hit in ranked:
        doc = qmd_get(hit.path)
        hit.excerpts = best_excerpts(doc, args.question)

    # --- Output ---
    if args.json_output:
        output = {
            "date": day,
            "collections": collections,
            "repo_filter": repo_filter,
            "total_matches": len(all_hits),
            "deduped": len(deduped),
            "hits": [
                {
                    "rank": i + 1,
                    "path": h.path,
                    "collection": h.collection,
                    "score": h.rank_score,
                    "is_subagent": h.is_subagent,
                    "excerpts": h.excerpts,
                }
                for i, h in enumerate(ranked)
            ],
        }
        json.dump(output, sys.stdout, indent=2)
        print()
        return 0

    # Text output
    print(f"Date: {day}")
    print(f"Collections: {', '.join(collections)}")
    if repo_filter:
        print(f"Repo filter: {repo_filter}")
    print(f"Matches: {len(all_hits)} (after dedup: {len(deduped)})")
    print()

    if not ranked:
        print("No date-scoped matches found.")
        return 0

    for idx, hit in enumerate(ranked, start=1):
        tag = " [subagent]" if hit.is_subagent else ""
        print(f"{idx}. {hit.path} (score={hit.rank_score:.2f}){tag}")
        for exc in hit.excerpts:
            print(f"   {exc['section']}:")
            for line in exc["text"].splitlines()[:3]:
                print(f"   - {line}")
        print()

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
