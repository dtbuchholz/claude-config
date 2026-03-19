#!/usr/bin/env bash
# PreCompact hook: analyzes transcript before compaction and logs a
# context health report. Since PreCompact can't inject compaction
# instructions directly, this writes a report to a file that the
# context-prune skill can reference, and emits stats to stderr for
# the user.
#
# Fires on: PreCompact (matcher: auto|manual)
set -euo pipefail

INPUT=$(cat)

TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // ""')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
CWD=$(echo "$INPUT" | jq -r '.cwd // "."')

if [ -z "$TRANSCRIPT" ] || [ ! -f "$TRANSCRIPT" ]; then
  exit 0
fi

# Analyze transcript for context composition
REPORT_DIR="${HOME}/.claude/context-reports"
mkdir -p "$REPORT_DIR"
REPORT="${REPORT_DIR}/${SESSION_ID}-$(date +%s).md"

python3 - "$TRANSCRIPT" "$REPORT" << 'PYEOF'
import json
import sys
from collections import Counter, defaultdict

transcript_path = sys.argv[1]
report_path = sys.argv[2]

tool_sizes = []      # (tool_name, input_summary, output_chars, line_num)
total_chars = 0
tool_counts = Counter()
large_outputs = []   # outputs > 2000 tokens (~8000 chars)

try:
    with open(transcript_path) as f:
        for i, line in enumerate(f, 1):
            line = line.strip()
            if not line:
                continue
            try:
                entry = json.loads(line)
            except json.JSONDecodeError:
                continue

            # Look for tool results in the conversation
            msg_type = entry.get("type", "")
            role = entry.get("role", "")

            if msg_type == "tool_result" or (role == "tool"):
                content = entry.get("content", "")
                if isinstance(content, list):
                    content = " ".join(
                        c.get("text", "") for c in content
                        if isinstance(c, dict) and c.get("type") == "text"
                    )
                char_count = len(str(content))
                token_est = char_count // 4
                tool_name = entry.get("tool_name", entry.get("name", "unknown"))

                tool_sizes.append((tool_name, char_count, token_est, i))
                tool_counts[tool_name] += 1
                total_chars += char_count

                if token_est > 2000:
                    large_outputs.append((tool_name, token_est, i))

except Exception as e:
    sys.stderr.write(f"Transcript analysis error: {e}\n")
    sys.exit(0)

total_tokens = total_chars // 4

# Write report
with open(report_path, "w") as f:
    f.write(f"# Context Health Report\n\n")
    f.write(f"- Total tool output: ~{total_tokens:,} tokens ({total_chars:,} chars)\n")
    f.write(f"- Tool calls: {sum(tool_counts.values())}\n")
    f.write(f"- Large outputs (>2k tokens): {len(large_outputs)}\n\n")

    if large_outputs:
        f.write("## Large Outputs (candidates for pruning)\n\n")
        f.write("| Tool | ~Tokens | Transcript Line |\n")
        f.write("|---|---|---|\n")
        for name, tokens, line in sorted(large_outputs, key=lambda x: -x[1]):
            f.write(f"| {name} | {tokens:,} | L{line} |\n")
        f.write("\n")

    f.write("## Tool Usage\n\n")
    for tool, count in tool_counts.most_common(10):
        f.write(f"- {tool}: {count} calls\n")

# Print summary to stderr (shown to user)
sys.stderr.write(f"📊 Context: ~{total_tokens:,} tokens in tool outputs, ")
sys.stderr.write(f"{len(large_outputs)} large outputs (>2k tokens)\n")
if large_outputs:
    top = large_outputs[0]
    sys.stderr.write(f"   Largest: {top[0]} at ~{top[1]:,} tokens\n")
sys.stderr.write(f"   Report: {report_path}\n")
PYEOF

exit 0
