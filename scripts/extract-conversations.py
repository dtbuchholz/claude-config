#!/usr/bin/env python3
from __future__ import annotations

"""Extract compact, high-signal digests from Claude and Codex conversation JSONL files.

Reads raw session transcripts and writes concise markdown digests optimized for retrieval:
- key user requests
- concrete assistant outcomes
- minimal noise/instructions

Output structure (one digest per session-day):
  Full transcripts (primary, indexed):
    ~/.claude/conversations/claude/<project-hash>/<session-id>__YYYY-MM-DD.md
    ~/.claude/conversations/codex/<YYYY>/<MM>/<DD>/<session-name>__YYYY-MM-DD.md
  Summaries (sidecar, optional):
    ~/.claude/conversations/summaries/claude/...
    ~/.claude/conversations/summaries/codex/...
"""

import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from zoneinfo import ZoneInfo

CLAUDE_PROJECTS = Path.home() / ".claude" / "projects"
CODEX_SESSIONS = Path.home() / ".codex" / "sessions"
OUTPUT_DIR = Path.home() / ".claude" / "conversations"
SUMMARY_DIR = OUTPUT_DIR / "summaries"
LOCAL_TZ = ZoneInfo("America/New_York")
MAX_USER_ITEMS = 6
MAX_ASSISTANT_ITEMS = 6
MAX_SECTION_ITEMS = 8
MAX_TEXT_CHARS = 420
MAX_FULL_TEXT_CHARS = 8000

NOISE_PATTERNS = [
    re.compile(r"^<environment_context>", re.IGNORECASE),
    re.compile(r"^Project Guidelines \(from .*?\)", re.IGNORECASE),
    re.compile(r"^Compact Instructions", re.IGNORECASE),
    re.compile(r"^You are reviewing code changes with NO prior context", re.IGNORECASE),
    re.compile(r"^CRITICAL:\s*Only report issues", re.IGNORECASE),
    re.compile(r"^#\s*AGENTS\b", re.IGNORECASE),
    re.compile(r"^##\s*Skills\b", re.IGNORECASE),
    re.compile(r"^\s*<INSTRUCTIONS>\s*$", re.IGNORECASE),
    re.compile(r"^\s*</INSTRUCTIONS>\s*$", re.IGNORECASE),
    re.compile(r"^\s*policy\s*=\s*\"never\"", re.IGNORECASE),
    re.compile(r"^Chunk ID:\s", re.IGNORECASE),
    re.compile(r"^Wall time:\s", re.IGNORECASE),
    re.compile(r"^Process exited with code\s", re.IGNORECASE),
    re.compile(r"^Original token count:\s", re.IGNORECASE),
    re.compile(r"^Output:\s*$", re.IGNORECASE),
    re.compile(r"^Tool result:\s*", re.IGNORECASE),
    re.compile(r"^Process running with session ID", re.IGNORECASE),
    re.compile(r"^<analysis>", re.IGNORECASE),
    re.compile(r"^</analysis>", re.IGNORECASE),
    re.compile(r"^Your task is to create a detailed summary of the conversation so far", re.IGNORECASE),
    re.compile(r"^HEARTBEAT_OK$", re.IGNORECASE),
    re.compile(r"^NO_REPLY$", re.IGNORECASE),
    re.compile(r"^ANNOUNCE_SKIP$", re.IGNORECASE),
    re.compile(r"compaction flush", re.IGNORECASE),
]

SIGNAL_HINTS = [
    "fixed",
    "added",
    "updated",
    "implemented",
    "created",
    "removed",
    "verified",
    "committed",
    "merged",
    "completed",
    "passed",
    "blocked",
    "failed",
    "error",
    "issue",
    "plan",
    "decision",
    "constraint",
    "tradeoff",
    "why",
    "because",
]

QUESTION_STARTERS = (
    "what ",
    "how ",
    "why ",
    "when ",
    "where ",
    "who ",
    "which ",
    "can ",
    "could ",
    "should ",
    "would ",
    "did ",
    "is ",
    "are ",
    "do ",
    "does ",
)

CONSTRAINT_HINTS = (
    "must",
    "should",
    "only",
    "don't",
    "do not",
    "cannot",
    "can't",
    "avoid",
    "ignore",
    "use ",
    "start with",
    "single commit",
    "public repo",
)

DECISION_HINTS = (
    "decide",
    "decision",
    "recommend",
    "best approach",
    "tradeoff",
    "we should",
    "let's",
    "instead",
)

ACTION_HINTS = (
    "added",
    "updated",
    "implemented",
    "created",
    "removed",
    "renamed",
    "fixed",
    "tested",
    "verified",
    "committed",
    "pushed",
    "configured",
    "installed",
    "ran",
)

ISSUE_HINTS = (
    "error",
    "failed",
    "leak",
    "blocked",
    "problem",
    "issue",
    "mismatch",
    "not found",
    "cannot",
    "can't",
)

OPEN_HINTS = (
    "next step",
    "next steps",
    "follow-up",
    "todo",
    "to do",
    "pending",
    "later",
    "can you",
    "should we",
)

PATH_TOKEN_RE = re.compile(r"`([^`]+)`")
ANSI_RE = re.compile(r"\x1B\[[0-?]*[ -/]*[@-~]")
PLAUSIBLE_PATH_RE = re.compile(
    r"(~?/[\w\-.~/]+|[\w\-.]+/[\w\-.~/]+|[\w\-.]+\.(md|py|ts|tsx|js|json|toml|sh|yaml|yml|plist))"
)
TOOL_OUTPUT_NOISE_PREFIXES = (
    "Chunk ID:",
    "Wall time:",
    "Process exited with code",
    "Original token count:",
    "Output:",
)
TOOL_RESULT_HINTS = ACTION_HINTS + ISSUE_HINTS + (
    "passed",
    "coverage",
    "commit",
    "push",
    "pytest",
    "lint",
    "build",
    "qmd",
    "hook",
    "plan",
)


def is_noise(text: str) -> bool:
    t = text.strip()
    if not t:
        return True
    return any(p.search(t) for p in NOISE_PATTERNS)


def normalize(text: str) -> str:
    t = ANSI_RE.sub("", text)
    t = " ".join(t.strip().split())
    if len(t) > MAX_TEXT_CHARS:
        t = t[:MAX_TEXT_CHARS].rstrip() + "..."
    return t


def normalize_full(text: str) -> str:
    t = ANSI_RE.sub("", text).replace("\r\n", "\n").replace("\r", "\n")
    clean_lines: list[str] = []
    for raw in t.splitlines():
        line = raw.rstrip()
        if not line:
            clean_lines.append("")
            continue
        if any(p.search(line.strip()) for p in NOISE_PATTERNS):
            continue
        clean_lines.append(line)
    t = "\n".join(clean_lines).strip()
    if len(t) > MAX_FULL_TEXT_CHARS:
        t = t[:MAX_FULL_TEXT_CHARS].rstrip() + "..."
    return t


def sanitize_tool_output(text: str) -> str:
    lines = []
    for raw in ANSI_RE.sub("", text).splitlines():
        line = raw.strip()
        if not line:
            continue
        if any(line.startswith(p) for p in TOOL_OUTPUT_NOISE_PREFIXES):
            continue
        lines.append(line)
    if not lines:
        return ""
    condensed = " ".join(lines)
    if len(condensed) > 220:
        condensed = condensed[:220].rstrip() + "..."
    return condensed


def should_keep_tool_result(text: str) -> bool:
    if not text:
        return False
    low = text.lower()
    if len(text) < 16:
        return False
    if PLAUSIBLE_PATH_RE.search(text):
        return True
    return any(h in low for h in TOOL_RESULT_HINTS)


def parse_timestamp(ts: str) -> datetime | None:
    if not ts:
        return None
    value = ts.strip()
    if value.endswith("Z"):
        value = value[:-1] + "+00:00"
    try:
        dt = datetime.fromisoformat(value)
    except ValueError:
        return None
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt


def date_key_from_ts(ts: str) -> str:
    dt = parse_timestamp(ts)
    if not dt:
        return "undated"
    return dt.astimezone(LOCAL_TZ).strftime("%Y-%m-%d")


def init_bucket() -> dict:
    return {"user_items": [], "assistant_items": [], "events": [], "first_ts": "", "last_ts": ""}


def bucket_for(buckets: dict[str, dict], ts: str) -> dict:
    key = date_key_from_ts(ts)
    if key not in buckets:
        buckets[key] = init_bucket()
    bucket = buckets[key]
    if ts:
        if not bucket["first_ts"]:
            bucket["first_ts"] = ts
        bucket["last_ts"] = ts
    return bucket


def append_event(bucket: dict, role: str, text: str, ts: str) -> None:
    cleaned = normalize_full(text)
    if not cleaned:
        return
    bucket["events"].append({"ts": ts, "role": role, "text": cleaned})
    if role == "user":
        bucket["user_items"].append(cleaned)
    elif role == "assistant":
        bucket["assistant_items"].append(cleaned)


def dedupe(items: list[str]) -> list[str]:
    seen = set()
    out: list[str] = []
    for item in items:
        if item in seen:
            continue
        seen.add(item)
        out.append(item)
    return out


def signal_score(text: str) -> int:
    t = text.lower()
    score = 0
    if any(h in t for h in SIGNAL_HINTS):
        score += 2
    if "/" in text or ".md" in text or ".ts" in text or ".py" in text or ".json" in text:
        score += 1
    if "```" in text or "git " in t or "npm " in t or "qmd " in t or "make " in t:
        score += 1
    n = len(text)
    if 40 <= n <= MAX_TEXT_CHARS:
        score += 1
    return score


def top_snippets(items: list[str], max_items: int) -> list[str]:
    cleaned = dedupe([normalize(x) for x in items if not is_noise(x)])
    ranked = sorted(cleaned, key=lambda x: signal_score(x), reverse=True)
    # Keep only informative snippets (score >= 1), fallback to first items if none pass.
    strong = [x for x in ranked if signal_score(x) >= 1]
    if strong:
        return strong[:max_items]
    return cleaned[:max_items]


def contains_any(text: str, hints: tuple[str, ...]) -> bool:
    t = text.lower()
    return any(h in t for h in hints)


def extract_artifacts(items: list[str]) -> list[str]:
    artifacts: list[str] = []
    for item in items:
        for m in PATH_TOKEN_RE.findall(item):
            if "/" in m or "." in m:
                artifacts.append(m)
        for m in PLAUSIBLE_PATH_RE.findall(item):
            token = m[0] if isinstance(m, tuple) else m
            if token:
                artifacts.append(token)
    clean = [normalize(x).strip(".,:;") for x in artifacts if x]
    return dedupe(clean)[:MAX_SECTION_ITEMS]


def summarize_user(user_items: list[str]) -> tuple[list[str], list[str], list[str]]:
    goals: list[str] = []
    constraints: list[str] = []
    questions: list[str] = []
    for item in user_items:
        low = item.lower().strip()
        if "?" in item or low.startswith(QUESTION_STARTERS):
            questions.append(item)
        if contains_any(item, CONSTRAINT_HINTS):
            constraints.append(item)
        if not is_noise(item):
            goals.append(item)
    return (
        top_snippets(goals, MAX_SECTION_ITEMS),
        top_snippets(constraints, MAX_SECTION_ITEMS),
        top_snippets(questions, MAX_SECTION_ITEMS),
    )


def summarize_assistant(
    assistant_items: list[str],
) -> tuple[list[str], list[str], list[str], list[str]]:
    decisions: list[str] = []
    actions: list[str] = []
    issues: list[str] = []
    open_threads: list[str] = []
    for item in assistant_items:
        if contains_any(item, DECISION_HINTS):
            decisions.append(item)
        if contains_any(item, ACTION_HINTS):
            actions.append(item)
        if contains_any(item, ISSUE_HINTS):
            issues.append(item)
        if contains_any(item, OPEN_HINTS):
            open_threads.append(item)

    return (
        top_snippets(decisions, MAX_SECTION_ITEMS),
        top_snippets(actions, MAX_SECTION_ITEMS),
        top_snippets(issues, MAX_SECTION_ITEMS),
        top_snippets(open_threads, MAX_SECTION_ITEMS),
    )


def build_digest(
    session_label: str,
    user_items: list[str],
    assistant_items: list[str],
    first_ts: str,
    last_ts: str,
) -> str:
    user_items = dedupe([normalize(x) for x in user_items if not is_noise(x)])
    assistant_items = dedupe([normalize(x) for x in assistant_items if not is_noise(x)])

    key_user = top_snippets(user_items, MAX_USER_ITEMS)
    key_assistant = top_snippets(assistant_items, MAX_ASSISTANT_ITEMS)
    goals, constraints, questions = summarize_user(user_items)
    decisions, actions, issues, open_threads = summarize_assistant(assistant_items)
    artifacts = extract_artifacts(user_items + assistant_items)
    # Preserve recency context for time-sensitive questions.
    last_user = user_items[-1] if user_items else ""
    last_assistant = assistant_items[-1] if assistant_items else ""

    lines = [f"# {session_label}", ""]
    lines.append("## Session Metadata")
    lines.append(f"- first_event: {first_ts or '(unknown)'}")
    lines.append(f"- last_event: {last_ts or '(unknown)'}")
    lines.append(f"- user_message_count: {len(user_items)}")
    lines.append(f"- assistant_message_count: {len(assistant_items)}")
    lines.append("")
    lines.append("## User Intent And Constraints")
    lines.append("### Goals")
    if goals:
        lines.extend([f"- {x}" for x in goals])
    else:
        lines.append("- (none extracted)")
    lines.append("### Constraints And Preferences")
    if constraints:
        lines.extend([f"- {x}" for x in constraints])
    else:
        lines.append("- (none extracted)")
    lines.append("### Questions")
    if questions:
        lines.extend([f"- {x}" for x in questions])
    else:
        lines.append("- (none extracted)")
    lines.append("")
    lines.append("## Assistant Work Summary")
    lines.append("### Decisions")
    if decisions:
        lines.extend([f"- {x}" for x in decisions])
    else:
        lines.append("- (none extracted)")
    lines.append("### Actions")
    if actions:
        lines.extend([f"- {x}" for x in actions])
    else:
        lines.append("- (none extracted)")
    lines.append("### Issues And Risks")
    if issues:
        lines.extend([f"- {x}" for x in issues])
    else:
        lines.append("- (none extracted)")
    lines.append("")
    lines.append("## Artifacts Mentioned")
    if artifacts:
        lines.extend([f"- {x}" for x in artifacts])
    else:
        lines.append("- (none extracted)")
    lines.append("")
    lines.append("## Key User Messages")
    if key_user:
        lines.extend([f"- {x}" for x in key_user])
    else:
        lines.append("- (none extracted)")
    lines.append("")
    lines.append("## Key Assistant Messages")
    if key_assistant:
        lines.extend([f"- {x}" for x in key_assistant])
    else:
        lines.append("- (none extracted)")
    lines.append("")
    lines.append("## Open Threads")
    if open_threads:
        lines.extend([f"- {x}" for x in open_threads])
    else:
        lines.append("- (none extracted)")
    lines.append("")
    lines.append("## Final Turn Context")
    if last_user:
        lines.append(f"- last_user: {normalize(last_user)}")
    else:
        lines.append("- last_user: (none)")
    if last_assistant:
        lines.append(f"- last_assistant: {normalize(last_assistant)}")
    else:
        lines.append("- last_assistant: (none)")
    lines.append("")
    return "\n".join(lines)


def format_local_time(ts: str) -> str:
    dt = parse_timestamp(ts)
    if not dt:
        return "??:??"
    return dt.astimezone(LOCAL_TZ).strftime("%H:%M")


def build_full_transcript(
    session_label: str,
    events: list[dict],
    first_ts: str,
    last_ts: str,
) -> str:
    lines = [f"# {session_label}", ""]
    lines.append("## Session Metadata")
    lines.append(f"- first_event: {first_ts or '(unknown)'}")
    lines.append(f"- last_event: {last_ts or '(unknown)'}")
    lines.append(f"- event_count: {len(events)}")
    lines.append("")
    lines.append("## Conversation")

    prev_key = None
    for ev in events:
        role = ev.get("role", "unknown")
        text = ev.get("text", "").strip()
        ts = ev.get("ts", "")
        if not text:
            continue
        key = (role, text)
        if key == prev_key:
            continue
        prev_key = key
        lines.append(f"### [{format_local_time(ts)}] {role}")
        lines.append(text)
        lines.append("")

    if len(lines) <= 8:
        lines.append("(no content extracted)")
    return "\n".join(lines).strip() + "\n"


def extract_claude(jsonl_path: Path) -> dict[str, dict[str, str]]:
    """Extract per-day full transcripts + compact digests from a Claude conversation JSONL."""
    buckets: dict[str, dict] = {}
    for raw in jsonl_path.open():
        try:
            entry = json.loads(raw)
        except json.JSONDecodeError:
            continue
        ts = str(entry.get("timestamp") or entry.get("created_at") or "").strip()
        msg = entry.get("message")
        if not msg:
            continue
        role = msg.get("role", "")
        content = msg.get("content", "")
        bucket = bucket_for(buckets, ts)

        if isinstance(content, str) and content.strip():
            if role == "user":
                append_event(bucket, "user", content.strip(), ts)
            elif role == "assistant":
                append_event(bucket, "assistant", content.strip(), ts)
        elif isinstance(content, list):
            for block in content:
                if not isinstance(block, dict):
                    continue
                btype = block.get("type", "")
                if btype == "text":
                    text = block.get("text", "").strip()
                    if text:
                        if role == "user":
                            append_event(bucket, "user", text, ts)
                        elif role == "assistant":
                            append_event(bucket, "assistant", text, ts)

    digests: dict[str, dict[str, str]] = {}
    for day_key, data in buckets.items():
        summary_text = build_digest(
            f"{jsonl_path.stem} [{day_key}]",
            data["user_items"],
            data["assistant_items"],
            data["first_ts"],
            data["last_ts"],
        )
        full_text = build_full_transcript(
            f"{jsonl_path.stem} [{day_key}]",
            data["events"],
            data["first_ts"],
            data["last_ts"],
        )
        if summary_text or full_text:
            digests[day_key] = {"summary": summary_text, "full": full_text}
    return digests


def extract_codex(jsonl_path: Path) -> dict[str, dict[str, str]]:
    """Extract per-day full transcripts + compact digests from a Codex conversation JSONL."""
    buckets: dict[str, dict] = {}
    for raw in jsonl_path.open():
        try:
            entry = json.loads(raw)
        except json.JSONDecodeError:
            continue
        ts = str(entry.get("timestamp") or entry.get("created_at") or "").strip()
        etype = entry.get("type", "")
        payload = entry.get("payload", {})
        bucket = bucket_for(buckets, ts)

        # User messages come as event_msg with type=user_message
        if etype == "event_msg" and payload.get("type") == "user_message":
            text = payload.get("message", "").strip()
            if text:
                append_event(bucket, "user", text, ts)
            continue

        # Assistant/user/developer messages come as response_item
        if etype == "response_item":
            ptype = payload.get("type", "")
            role = payload.get("role", "")

            if ptype == "message" and role in ("user", "assistant"):
                for block in payload.get("content", []):
                    if isinstance(block, dict) and block.get("type") in ("text", "input_text", "output_text"):
                        text = block.get("text", "").strip()
                        if text:
                            if role == "user":
                                append_event(bucket, "user", text, ts)
                            elif role == "assistant":
                                append_event(bucket, "assistant", text, ts)

    digests: dict[str, dict[str, str]] = {}
    for day_key, data in buckets.items():
        summary_text = build_digest(
            f"{jsonl_path.stem} [{day_key}]",
            data["user_items"],
            data["assistant_items"],
            data["first_ts"],
            data["last_ts"],
        )
        full_text = build_full_transcript(
            f"{jsonl_path.stem} [{day_key}]",
            data["events"],
            data["first_ts"],
            data["last_ts"],
        )
        if summary_text or full_text:
            digests[day_key] = {"summary": summary_text, "full": full_text}
    return digests


def clear_output():
    for base in (OUTPUT_DIR, SUMMARY_DIR):
        if not base.exists():
            continue
        for md in base.rglob("*.md"):
            md.unlink()


def process_claude():
    """Process all Claude conversation files."""
    if not CLAUDE_PROJECTS.exists():
        return 0, 0
    out_dir = OUTPUT_DIR / "claude"
    summary_dir = SUMMARY_DIR / "claude"
    total, written = 0, 0
    for jsonl in CLAUDE_PROJECTS.rglob("*.jsonl"):
        total += 1
        by_day = extract_claude(jsonl)
        if not by_day:
            continue
        # Preserve project-hash/session-id structure
        rel = jsonl.relative_to(CLAUDE_PROJECTS)
        rel_no_ext = rel.with_suffix("")
        for day_key, payload in by_day.items():
            dest = rel_no_ext.parent / f"{rel_no_ext.name}__{day_key}.md"
            out_path = out_dir / dest
            summary_path = summary_dir / dest
            out_path.parent.mkdir(parents=True, exist_ok=True)
            summary_path.parent.mkdir(parents=True, exist_ok=True)
            out_path.write_text(payload["full"])
            summary_path.write_text(payload["summary"])
            written += 1
    return total, written


def process_codex():
    """Process all Codex conversation files."""
    if not CODEX_SESSIONS.exists():
        return 0, 0
    out_dir = OUTPUT_DIR / "codex"
    summary_dir = SUMMARY_DIR / "codex"
    total, written = 0, 0
    for jsonl in CODEX_SESSIONS.rglob("*.jsonl"):
        total += 1
        by_day = extract_codex(jsonl)
        if not by_day:
            continue
        rel = jsonl.relative_to(CODEX_SESSIONS)
        rel_no_ext = rel.with_suffix("")
        for day_key, payload in by_day.items():
            dest = rel_no_ext.parent / f"{rel_no_ext.name}__{day_key}.md"
            out_path = out_dir / dest
            summary_path = summary_dir / dest
            out_path.parent.mkdir(parents=True, exist_ok=True)
            summary_path.parent.mkdir(parents=True, exist_ok=True)
            out_path.write_text(payload["full"])
            summary_path.write_text(payload["summary"])
            written += 1
    return total, written


def main():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    clear_output()

    c_total, c_written = process_claude()
    x_total, x_written = process_codex()

    print(f"Claude: {c_written} day-digests from {c_total} sessions")
    print(f"Codex:  {x_written} day-digests from {x_total} sessions")

    # Show size comparison
    claude_raw = sum(f.stat().st_size for f in CLAUDE_PROJECTS.rglob("*.jsonl")) if CLAUDE_PROJECTS.exists() else 0
    codex_raw = sum(f.stat().st_size for f in CODEX_SESSIONS.rglob("*.jsonl")) if CODEX_SESSIONS.exists() else 0
    extracted = sum(f.stat().st_size for f in OUTPUT_DIR.rglob("*.md"))

    raw_mb = (claude_raw + codex_raw) / 1024 / 1024
    ext_mb = extracted / 1024 / 1024
    pct = (ext_mb / raw_mb * 100) if raw_mb else 0
    print(f"\nRaw: {raw_mb:.1f} MB -> Extracted: {ext_mb:.1f} MB ({pct:.0f}%)")


if __name__ == "__main__":
    main()
