#!/usr/bin/env python3
"""Extract high-signal text from Claude and Codex conversation JSONL files.

Reads raw session transcripts, strips tool calls/results/thinking/reasoning,
and writes clean markdown files suitable for QMD indexing.

Output structure:
  ~/.claude/conversations/claude/<project-hash>/<session-id>.md
  ~/.claude/conversations/codex/<YYYY>/<MM>/<DD>/<session-name>.md
"""

import json
import sys
from pathlib import Path

CLAUDE_PROJECTS = Path.home() / ".claude" / "projects"
CODEX_SESSIONS = Path.home() / ".codex" / "sessions"
OUTPUT_DIR = Path.home() / ".claude" / "conversations"


def extract_claude(jsonl_path: Path) -> str:
    """Extract user + assistant text from a Claude conversation JSONL."""
    lines = []
    for raw in jsonl_path.open():
        try:
            entry = json.loads(raw)
        except json.JSONDecodeError:
            continue
        msg = entry.get("message")
        if not msg:
            continue
        role = msg.get("role", "")
        content = msg.get("content", "")

        if isinstance(content, str) and content.strip():
            lines.append(f"**{role}**: {content.strip()}")
        elif isinstance(content, list):
            for block in content:
                if isinstance(block, dict) and block.get("type") == "text":
                    text = block.get("text", "").strip()
                    if text:
                        lines.append(f"**{role}**: {text}")
    return "\n\n".join(lines)


def extract_codex(jsonl_path: Path) -> str:
    """Extract user + assistant text from a Codex conversation JSONL."""
    lines = []
    for raw in jsonl_path.open():
        try:
            entry = json.loads(raw)
        except json.JSONDecodeError:
            continue
        etype = entry.get("type", "")
        payload = entry.get("payload", {})

        # User messages come as event_msg with type=user_message
        if etype == "event_msg" and payload.get("type") == "user_message":
            text = payload.get("message", "").strip()
            if text:
                lines.append(f"**user**: {text}")
            continue

        # Assistant/user/developer messages come as response_item
        if etype == "response_item":
            ptype = payload.get("type", "")
            role = payload.get("role", "")

            if ptype == "message" and role in ("user", "developer", "assistant"):
                for block in payload.get("content", []):
                    if isinstance(block, dict) and block.get("type") == "text":
                        text = block.get("text", "").strip()
                        if text:
                            lines.append(f"**{role}**: {text}")
    return "\n\n".join(lines)


def process_claude():
    """Process all Claude conversation files."""
    if not CLAUDE_PROJECTS.exists():
        return 0, 0
    out_dir = OUTPUT_DIR / "claude"
    total, written = 0, 0
    for jsonl in CLAUDE_PROJECTS.rglob("*.jsonl"):
        total += 1
        text = extract_claude(jsonl)
        if not text:
            continue
        # Preserve project-hash/session-id structure
        rel = jsonl.relative_to(CLAUDE_PROJECTS)
        dest = out_dir / rel.with_suffix(".md")
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(text)
        written += 1
    return total, written


def process_codex():
    """Process all Codex conversation files."""
    if not CODEX_SESSIONS.exists():
        return 0, 0
    out_dir = OUTPUT_DIR / "codex"
    total, written = 0, 0
    for jsonl in CODEX_SESSIONS.rglob("*.jsonl"):
        total += 1
        text = extract_codex(jsonl)
        if not text:
            continue
        rel = jsonl.relative_to(CODEX_SESSIONS)
        dest = out_dir / rel.with_suffix(".md")
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(text)
        written += 1
    return total, written


def main():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    c_total, c_written = process_claude()
    x_total, x_written = process_codex()

    print(f"Claude: {c_written}/{c_total} sessions extracted")
    print(f"Codex:  {x_written}/{x_total} sessions extracted")

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
