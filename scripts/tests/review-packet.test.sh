#!/usr/bin/env bash
# Tests for scripts/review-packet.sh. Run: bash scripts/tests/review-packet.test.sh
set -euo pipefail

SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/review-packet.sh"
BASH_BIN="${BASH_BIN:-bash}"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/review-packet-test.XXXXXX")"
cleanup() {
  chmod -R u+w "$TMP_ROOT" 2>/dev/null || true
  rm -rf "${TMP_ROOT:?}"
}
trap cleanup EXIT

pass=0
fail() {
  echo "FAIL: $*" >&2
  exit 1
}
ok() {
  pass=$((pass + 1))
}
expect_kv() {
  local out="$1" key="$2" want="$3" got
  got="$(printf '%s\n' "$out" | sed -n "s/^$key=//p" | head -1)"
  [[ "$got" == "$want" ]] || fail "$key: want '$want', got '$got'"$'\n'"$out"
}
packet() { "$BASH_BIN" "$SCRIPT" "$@"; }

make_repo() {
  local dir="$TMP_ROOT/$1"
  mkdir -p "$dir"
  git -C "$dir" init -q -b main
  git -C "$dir" config user.email t@example.com
  git -C "$dir" config user.name test
  git -C "$dir" config commit.gpgsign false
  printf 'def a():\n    return 1\n' >"$dir/app.py"
  printf '# Readme\n' >"$dir/README.md"
  printf 'lock v1\n' >"$dir/uv.lock"
  git -C "$dir" add -A
  git -C "$dir" commit -qm init
  printf '%s' "$dir"
}

# 1. Working tree: staged + unstaged + untracked; lockfile excluded by default.
repo="$(make_repo wt)"
printf 'def a():\n    return 2\n' >"$repo/app.py"
printf 'def v(x):\n    return x\n' >"$repo/validation.py"
mkdir -p "$repo/tests" && printf 'def test_v():\n    pass\n' >"$repo/tests/test_v.py"
printf 'lock v2\n' >"$repo/uv.lock"
git -C "$repo" add app.py
out="$(packet build "$repo" --out-dir "$TMP_ROOT/p1")"
expect_kv "$out" scope_kind working-tree
expect_kv "$out" files 3
expect_kv "$out" untracked 2
expect_kv "$out" excluded 1
expect_kv "$out" docs_only false
grep -q '^+def v(x):' "$TMP_ROOT/p1/packet.diff" || fail "untracked file content missing from packet"
grep -q 'dependency-lockfile	uv.lock' "$TMP_ROOT/p1/excluded-files.tsv" || fail "lockfile not listed as excluded"
[[ ! -w "$TMP_ROOT/p1/packet.diff" ]] || fail "packet should be read-only"
[[ ! -w "$TMP_ROOT/p1" ]] || fail "packet directory itself should be read-only"
grep -q '^packet.diff	' "$TMP_ROOT/p1/manifest.tsv" || fail "manifest should list packet.diff"
ok

# 2. Lockfiles opt-in.
out="$(packet build "$repo" --include-lockfiles --out-dir "$TMP_ROOT/p2")"
expect_kv "$out" files 4
expect_kv "$out" excluded 0
ok

# 3. Verify: ok, then drift after an edit, then tampered after the packet is modified.
out="$(packet verify "$TMP_ROOT/p1")" || fail "verify should pass on unchanged tree: $out"
expect_kv "$out" status ok
printf 'def v(x):\n    return -x\n' >"$repo/validation.py"
set +e
out="$(packet verify "$TMP_ROOT/p1")"
rc=$?
set -e
[[ $rc -eq 1 ]] || fail "verify drift exit: want 1, got $rc"
expect_kv "$out" status drift
expect_kv "$out" drifted validation.py
chmod u+w "$TMP_ROOT/p1/packet.diff" && printf 'x\n' >>"$TMP_ROOT/p1/packet.diff"
set +e
out="$(packet verify "$TMP_ROOT/p1")"
rc=$?
set -e
[[ $rc -eq 3 ]] || fail "verify tampered exit: want 3, got $rc"
expect_kv "$out" status tampered
ok

# 4. Branch scope includes committed, uncommitted, and untracked changes.
repo="$(make_repo br)"
git -C "$repo" checkout -qb feature
printf 'def a():\n    return 3\n' >"$repo/app.py"
git -C "$repo" commit -qam change
printf 'more\n' >>"$repo/README.md"
printf 'new\n' >"$repo/new.py"
out="$(packet build "$repo" --out-dir "$TMP_ROOT/p4")"
expect_kv "$out" scope_kind branch
expect_kv "$out" files 3
expect_kv "$out" untracked 1
ok

# 5. Range scope covers committed history only.
out="$(packet build "$repo" --range main..feature --out-dir "$TMP_ROOT/p5")"
expect_kv "$out" scope_kind range
expect_kv "$out" files 1
expect_kv "$out" untracked 0
ok

# 6. Docs-only detection; relative project dir round-trips through verify.
repo="$(make_repo docs)"
printf 'more docs\n' >>"$repo/README.md"
mkdir -p "$repo/docs" && printf 'guide\n' >"$repo/docs/guide.txt"
out="$(cd "$repo" && packet build . --out-dir "$TMP_ROOT/p6")"
expect_kv "$out" docs_only true
expect_kv "$out" typed false
out="$(cd "$TMP_ROOT" && packet verify "$TMP_ROOT/p6")" || fail "verify from another cwd failed: $out"
ok

# 7. On main with only uncommitted changes, auto scope picks the working tree.
repo="$(make_repo onmain)"
printf 'x = 1\n' >"$repo/only_new.ts"
out="$(packet build "$repo" --out-dir "$TMP_ROOT/p7")"
expect_kv "$out" scope_kind working-tree
expect_kv "$out" typed true
ok

# 8. Clean tree, and lockfile-only changes, are errors.
repo="$(make_repo clean)"
packet build "$repo" --out-dir "$TMP_ROOT/p8" >/dev/null 2>&1 && fail "clean tree should error"
printf 'lock v3\n' >"$repo/uv.lock"
err="$(packet build "$repo" --out-dir "$TMP_ROOT/p9" 2>&1 >/dev/null || true)"
[[ "$err" == *"--include-lockfiles"* ]] || fail "lockfile-only change should suggest --include-lockfiles: $err"
ok

# 9. Verify treats an added, removed, or edited packet file as tampering, not just packet.diff.
repo="$(make_repo extra)"
printf 'def a():\n    return 4\n' >"$repo/app.py"
packet build "$repo" --out-dir "$TMP_ROOT/p10" >/dev/null
chmod u+w "$TMP_ROOT/p10" && : >"$TMP_ROOT/p10/stray.txt"
set +e
out="$(packet verify "$TMP_ROOT/p10")"
rc=$?
set -e
[[ $rc -eq 3 ]] || fail "extra packet file: want exit 3, got $rc"$'\n'"$out"
expect_kv "$out" status tampered
expect_kv "$out" tampered stray.txt
rm -f "$TMP_ROOT/p10/stray.txt"
out="$(packet verify "$TMP_ROOT/p10")" || fail "verify should pass once the stray file is gone: $out"
chmod u+w "$TMP_ROOT/p10/index.tsv" && printf 'x\n' >>"$TMP_ROOT/p10/index.tsv"
set +e
out="$(packet verify "$TMP_ROOT/p10")"
rc=$?
set -e
[[ $rc -eq 3 ]] || fail "edited index.tsv: want exit 3, got $rc"
expect_kv "$out" tampered index.tsv
ok

# 10. --plan freezes a copy, resolves relative paths, and plan edits count as drift.
repo="$(make_repo plan)"
printf 'def a():\n    return 5\n' >"$repo/app.py"
mkdir -p "$TMP_ROOT/specs" && printf '# Plan\n- return 5\n' >"$TMP_ROOT/specs/PLAN.md"
out="$(cd "$TMP_ROOT/specs" && packet build "$repo" --plan PLAN.md --out-dir "$TMP_ROOT/p11")"
expect_kv "$out" plan "$(cd "$TMP_ROOT/p11" && pwd)/plan.md"
expect_kv "$out" plan_source "$(cd "$TMP_ROOT/specs" && pwd -P)/PLAN.md"
cmp -s "$TMP_ROOT/specs/PLAN.md" "$TMP_ROOT/p11/plan.md" || fail "plan.md should be a copy of the plan"
expect_kv "$out" files 1
out="$(cd "$TMP_ROOT" && packet verify "$TMP_ROOT/p11")" || fail "verify with plan should pass: $out"
printf -- '- also return 6\n' >>"$TMP_ROOT/specs/PLAN.md"
set +e
out="$(packet verify "$TMP_ROOT/p11")"
rc=$?
set -e
[[ $rc -eq 1 ]] || fail "plan drift: want exit 1, got $rc"$'\n'"$out"
expect_kv "$out" status drift
expect_kv "$out" drifted "plan:$(cd "$TMP_ROOT/specs" && pwd -P)/PLAN.md"
# Relative plan paths fall back to the project root; an in-repo plan is excluded from the diff.
mkdir -p "$repo/.plans" && printf 'root plan\n' >"$repo/.plans/P.md"
out="$(cd "$TMP_ROOT" && packet build "$repo" --plan .plans/P.md --out-dir "$TMP_ROOT/p12")"
expect_kv "$out" plan_source "$(cd "$repo" && pwd -P)/.plans/P.md"
expect_kv "$out" files 1
expect_kv "$out" excluded 1
grep -q '^plan	.plans/P.md$' "$TMP_ROOT/p12/excluded-files.tsv" || fail "in-repo plan should be excluded"
out="$(cd "$TMP_ROOT" && packet verify "$TMP_ROOT/p12")" || fail "verify with in-repo plan should pass: $out"
packet build "$repo" --plan missing.md --out-dir "$TMP_ROOT/p13" >/dev/null 2>&1 && fail "missing plan should error"
ok

echo "review-packet: $pass groups passed ($BASH_BIN)"
