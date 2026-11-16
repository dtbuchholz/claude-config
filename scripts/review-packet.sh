#!/usr/bin/env bash
# Build or verify a frozen code-review packet. Shared by the Claude and Codex review skills
# (pr-review, review-and-fix, agent-review, and the Codex deep pipeline) so scope detection,
# untracked-file handling, lockfile filtering, and hashing behave the same everywhere.
set -euo pipefail

usage() {
  cat <<'EOF'
usage:
  review-packet.sh build [project_dir] [--out-dir <dir>] [--range <git-range> | --base <ref> | --uncommitted]
                         [--path <pathspec>]... [--context-lines <n>] [--include-lockfiles]
                         [--plan <file>]
  review-packet.sh verify <out_dir>

build writes a read-only packet to <out_dir> (default: a new mktemp dir) and prints key=value lines:
  out_dir, packet, sha256, bytes, scope_kind, scope_label, files, excluded, untracked, docs_only, typed
  and, with --plan: plan, plan_source, plan_sha256

--plan copies a spec or acceptance-criteria file into the packet as plan.md so reviewers read a
frozen copy. A relative path resolves against the current directory, then the project root. If the
plan file is itself a changed or untracked file in scope, it is excluded from the diff (reason plan).

Scope (first match wins unless one is given explicitly):
  --range R       git diff R (committed history only; no working tree, no untracked files)
  --base B        changes since merge-base(B, HEAD), including uncommitted and untracked files
  --uncommitted   changes since HEAD, including staged, unstaged, and untracked files
  auto            --base <default branch> when HEAD has commits ahead of it, else --uncommitted
                  when the working tree is dirty, else error

Output files:
  packet.diff         concatenated per-file diffs (the frozen review payload)
  changed-files.txt   files in the packet
  excluded-files.tsv  reason<TAB>path for files left out (lockfiles unless --include-lockfiles)
  untracked-files.txt untracked files included in the packet
  index.tsv           path<TAB>diff file<TAB>bytes<TAB>sha256, one line per packet file
  plan.md             frozen copy of the --plan file (only with --plan)
  meta.env            the key=value summary above
  args.txt            build arguments, used by verify
  manifest.tsv        path<TAB>sha256 for every other file in the packet directory

The whole directory, including the directory itself, is read-only after build.

verify first checks the packet directory against manifest.tsv (any added, removed, or changed file
is tampering), then rebuilds the packet from the live checkout with the recorded arguments and
compares hashes. A changed --plan file counts as drift (drifted=plan:<path>). It prints status=ok,
status=drift (with drifted=<path> lines), or status=tampered (with tampered=<path> lines when the
manifest disagrees), and exits 0, 1, or 3 respectively. Exit 2 is a usage or git error.
EOF
}

die() {
  echo "error: $*" >&2
  exit 2
}

sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | cut -d' ' -f1
  else
    shasum -a 256 "$1" | cut -d' ' -f1
  fi
}

excluded_file_reason() {
  local base="${1##*/}"
  case "$base" in
    pnpm-lock.yaml | package-lock.json | npm-shrinkwrap.json | yarn.lock | bun.lock | bun.lockb)
      printf '%s' 'javascript-lockfile'
      ;;
    Cargo.lock | Gemfile.lock | Pipfile.lock | poetry.lock | uv.lock | pdm.lock | composer.lock | go.sum)
      printf '%s' 'dependency-lockfile'
      ;;
    gradle.lockfile | pubspec.lock | Podfile.lock | Package.resolved | packages.lock.json | flake.lock)
      printf '%s' 'dependency-lockfile'
      ;;
    *.lock)
      printf '%s' 'lockfile'
      ;;
    *)
      return 1
      ;;
  esac
}

manifest_of() {
  (cd "$1" && find . -type f ! -name manifest.tsv | sed 's|^\./||' | LC_ALL=C sort) |
    while IFS= read -r f; do
      printf '%s\t%s\n' "$f" "$(sha256_of "$1/$f")"
    done
}

build() {
  local project_dir="" out_dir="" range="" base="" uncommitted=0 context_lines=3 include_lockfiles=0
  local plan="" path_filters=() a

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --out-dir) out_dir="${2:?--out-dir needs a value}"; shift 2 ;;
      --range) range="${2:?--range needs a value}"; shift 2 ;;
      --base) base="${2:?--base needs a value}"; shift 2 ;;
      --uncommitted) uncommitted=1; shift ;;
      --path) path_filters+=("${2:?--path needs a value}"); shift 2 ;;
      --context-lines) context_lines="${2:?--context-lines needs a value}"; shift 2 ;;
      --include-lockfiles) include_lockfiles=1; shift ;;
      --plan) plan="${2:?--plan needs a value}"; shift 2 ;;
      -h | --help) usage; exit 0 ;;
      -*) die "unknown option: $1" ;;
      *)
        [[ -z "$project_dir" ]] || die "unexpected argument: $1"
        project_dir="$1"
        shift
        ;;
    esac
  done

  project_dir="${project_dir:-$(pwd)}"
  project_dir="$(git -C "$project_dir" rev-parse --show-toplevel 2>/dev/null)" ||
    die "not a git repository: ${project_dir}"
  [[ "$context_lines" =~ ^[0-9]+$ ]] || die "--context-lines must be a non-negative integer"
  if [[ -n "$plan" ]]; then
    if [[ "$plan" != /* ]]; then
      if [[ -f "$PWD/$plan" ]]; then
        plan="$PWD/$plan"
      else
        plan="$project_dir/$plan"
      fi
    fi
    [[ -f "$plan" ]] || die "plan file not found: $plan"
    # Physical path, so it compares equal to project_dir (git reports the physical root).
    plan="$(cd "$(dirname "$plan")" && pwd -P)/$(basename "$plan")"
  fi
  local explicit=$(((${#range} > 0) + (${#base} > 0) + uncommitted))
  [[ $explicit -le 1 ]] || die "use only one of --range, --base, --uncommitted"

  local pathspec=(--)
  if [[ ${#path_filters[@]} -gt 0 ]]; then
    pathspec+=("${path_filters[@]}")
  fi

  local default_branch=""
  if ref="$(git -C "$project_dir" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null)"; then
    default_branch="${ref#refs/remotes/origin/}"
  fi
  if [[ -z "$default_branch" ]]; then
    default_branch="$(git -C "$project_dir" branch --format='%(refname:short)' | grep -E '^(main|master)$' | head -1 || true)"
  fi

  if [[ $explicit -eq 0 ]]; then
    local ahead=0
    if [[ -n "$default_branch" ]]; then
      ahead="$(git -C "$project_dir" rev-list --count "${default_branch}..HEAD" 2>/dev/null || echo 0)"
    fi
    if [[ "$ahead" != "0" ]]; then
      base="$default_branch"
    elif [[ -n "$(git -C "$project_dir" status --porcelain)" ]]; then
      uncommitted=1
    else
      die "nothing to review in $project_dir (no commits ahead of ${default_branch:-a default branch}, clean working tree)"
    fi
  fi

  # diff_from: the ref the working tree (or range) is compared against.
  local scope_kind scope_label diff_from="" with_untracked=1
  if [[ -n "$range" ]]; then
    scope_kind="range"
    scope_label="range:$range"
    with_untracked=0
  elif [[ -n "$base" ]]; then
    diff_from="$(git -C "$project_dir" merge-base "$base" HEAD 2>/dev/null)" ||
      die "cannot find merge-base of '$base' and HEAD"
    scope_kind="branch"
    scope_label="branch:${base}...HEAD+working-tree"
  else
    diff_from="HEAD"
    scope_kind="working-tree"
    scope_label="working-tree"
  fi

  if [[ -z "$out_dir" ]]; then
    out_dir="$(mktemp -d "${TMPDIR:-/tmp}/review-packet.XXXXXX")"
  elif [[ -e "$out_dir" && -n "$(ls -A "$out_dir" 2>/dev/null)" ]]; then
    die "--out-dir must be empty or absent: $out_dir"
  fi
  mkdir -p "$out_dir/diffs"
  out_dir="$(cd "$out_dir" && pwd)"

  # Record the resolved arguments (scope pinned, even when auto-detected) for verify.
  {
    printf '%s\n' "$project_dir"
    if [[ -n "$range" ]]; then
      printf '%s\n%s\n' --range "$range"
    elif [[ -n "$base" ]]; then
      printf '%s\n%s\n' --base "$base"
    else
      printf '%s\n' --uncommitted
    fi
    for a in ${path_filters[@]+"${path_filters[@]}"}; do printf '%s\n%s\n' --path "$a"; done
    printf '%s\n%s\n' --context-lines "$context_lines"
    [[ $include_lockfiles -eq 0 ]] || printf '%s\n' --include-lockfiles
    [[ -z "$plan" ]] || printf '%s\n%s\n' --plan "$plan"
  } >"$out_dir/args.txt"

  local all_files="$out_dir/.all-files.txt" untracked_all="$out_dir/.untracked-all.txt"
  : >"$untracked_all"
  if [[ $with_untracked -eq 1 ]]; then
    git -C "$project_dir" ls-files --others --exclude-standard "${pathspec[@]}" | sed '/^$/d' | sort -u >"$untracked_all"
  fi
  {
    if [[ -n "$range" ]]; then
      git -C "$project_dir" diff --name-only --no-ext-diff "$range" "${pathspec[@]}"
    else
      git -C "$project_dir" diff --name-only --no-ext-diff "$diff_from" "${pathspec[@]}"
    fi
    cat "$untracked_all"
  } | sed '/^$/d' | sort -u >"$all_files"

  : >"$out_dir/changed-files.txt"
  : >"$out_dir/excluded-files.tsv"
  : >"$out_dir/untracked-files.txt"
  : >"$out_dir/index.tsv"
  : >"$out_dir/packet.diff"

  local path reason n=0 diff_file rc
  while IFS= read -r path; do
    [[ -n "$path" ]] || continue
    # The plan is the spec the diff is judged against, not part of the change under review.
    if [[ -n "$plan" && "$project_dir/$path" == "$plan" ]]; then
      printf '%s\t%s\n' plan "$path" >>"$out_dir/excluded-files.tsv"
      continue
    fi
    if [[ $include_lockfiles -eq 0 ]] && reason="$(excluded_file_reason "$path")"; then
      printf '%s\t%s\n' "$reason" "$path" >>"$out_dir/excluded-files.tsv"
      continue
    fi
    n=$((n + 1))
    diff_file="diffs/$(printf '%04d' "$n").diff"
    if grep -Fxq -- "$path" "$untracked_all"; then
      printf '%s\n' "$path" >>"$out_dir/untracked-files.txt"
      rc=0
      (cd "$project_dir" && git diff --no-index --no-ext-diff "-U$context_lines" -- /dev/null "$path") \
        >"$out_dir/$diff_file" || rc=$?
      [[ $rc -le 1 ]] || die "failed to diff untracked file: $path"
    elif [[ -n "$range" ]]; then
      git -C "$project_dir" diff --no-ext-diff "-U$context_lines" "$range" -- "$path" >"$out_dir/$diff_file"
    else
      git -C "$project_dir" diff --no-ext-diff "-U$context_lines" "$diff_from" -- "$path" >"$out_dir/$diff_file"
    fi
    if [[ ! -s "$out_dir/$diff_file" ]]; then
      # Mode-only or otherwise empty change; nothing for a reviewer to read.
      rm -f "$out_dir/$diff_file"
      n=$((n - 1))
      continue
    fi
    printf '%s\n' "$path" >>"$out_dir/changed-files.txt"
    printf '%s\t%s\t%s\t%s\n' "$path" "$diff_file" "$(wc -c <"$out_dir/$diff_file" | tr -d ' ')" \
      "$(sha256_of "$out_dir/$diff_file")" >>"$out_dir/index.tsv"
    cat "$out_dir/$diff_file" >>"$out_dir/packet.diff"
  done <"$all_files"
  rm -f "$all_files" "$untracked_all"

  if [[ $n -eq 0 ]]; then
    if [[ -s "$out_dir/excluded-files.tsv" ]]; then
      echo "error: every changed file was excluded by default:" >&2
      sed 's/^/  /' "$out_dir/excluded-files.tsv" >&2
      echo "error: pass --include-lockfiles if these are the intended review target" >&2
      exit 2
    fi
    die "no diff content for scope $scope_label"
  fi

  local docs_only=true typed=false
  grep -Evq '(\.(md|mdx|markdown|rst|txt|adoc)$|^docs/|/docs/|(^|/)(LICENSE|CHANGELOG|NOTICE)[^/]*$)' \
    "$out_dir/changed-files.txt" && docs_only=false
  grep -Eq '\.(ts|tsx|mts|cts|rs|go|java|kt|scala|swift|cs|pyi)$' "$out_dir/changed-files.txt" && typed=true

  [[ -z "$plan" ]] || cp "$plan" "$out_dir/plan.md"

  {
    printf 'out_dir=%s\n' "$out_dir"
    printf 'packet=%s\n' "$out_dir/packet.diff"
    printf 'sha256=%s\n' "$(sha256_of "$out_dir/packet.diff")"
    printf 'bytes=%s\n' "$(wc -c <"$out_dir/packet.diff" | tr -d ' ')"
    printf 'scope_kind=%s\n' "$scope_kind"
    printf 'scope_label=%s\n' "$scope_label"
    printf 'files=%s\n' "$n"
    printf 'excluded=%s\n' "$(wc -l <"$out_dir/excluded-files.tsv" | tr -d ' ')"
    printf 'untracked=%s\n' "$(wc -l <"$out_dir/untracked-files.txt" | tr -d ' ')"
    printf 'docs_only=%s\n' "$docs_only"
    printf 'typed=%s\n' "$typed"
    if [[ -n "$plan" ]]; then
      printf 'plan=%s\n' "$out_dir/plan.md"
      printf 'plan_source=%s\n' "$plan"
      printf 'plan_sha256=%s\n' "$(sha256_of "$out_dir/plan.md")"
    fi
  } >"$out_dir/meta.env"

  manifest_of "$out_dir" >"$out_dir/manifest.tsv"
  chmod -R a-w "$out_dir"
  cat "$out_dir/meta.env"
}

meta_value() {
  sed -n "s/^$1=//p" "$2" | head -1
}

verify() {
  local dir="${1:?usage: review-packet.sh verify <out_dir>}"
  [[ -f "$dir/meta.env" && -f "$dir/args.txt" ]] || die "not a review packet directory: $dir"

  local recorded actual tampered=""
  recorded="$(meta_value sha256 "$dir/meta.env")"
  actual="$(sha256_of "$dir/packet.diff")"
  if [[ -f "$dir/manifest.tsv" ]]; then
    # A line present in only one listing is an added, removed, or changed packet file.
    tampered="$(LC_ALL=C comm -3 "$dir/manifest.tsv" <(manifest_of "$dir") | sed 's/^[[:space:]]*//' | cut -f1 |
      LC_ALL=C sort -u)"
  fi
  if [[ "$recorded" != "$actual" || -n "$tampered" ]]; then
    printf 'status=tampered\nrecorded=%s\nactual=%s\n' "$recorded" "$actual"
    [[ -z "$tampered" ]] || printf '%s\n' "$tampered" | sed 's/^/tampered=/'
    exit 3
  fi

  local args=() line
  while IFS= read -r line; do args+=("$line"); done <"$dir/args.txt"
  local work fresh
  work="$(mktemp -d "${TMPDIR:-/tmp}/review-packet-verify.XXXXXX")"
  fresh="$work/packet"
  local rebuilt_ok=1
  (build "${args[@]}" --out-dir "$fresh") >/dev/null 2>"$work/stderr" || rebuilt_ok=0

  local live="" live_plan="" recorded_plan status=1
  recorded_plan="$(meta_value plan_sha256 "$dir/meta.env")"
  if [[ $rebuilt_ok -eq 1 ]]; then
    live="$(meta_value sha256 "$fresh/meta.env")"
    live_plan="$(meta_value plan_sha256 "$fresh/meta.env")"
  fi
  if [[ "$live" == "$recorded" && "$live_plan" == "$recorded_plan" ]]; then
    printf 'status=ok\nsha256=%s\n' "$recorded"
    status=0
  else
    printf 'status=drift\nrecorded=%s\nlive=%s\n' "$recorded" "${live:-<rebuild failed: $(head -1 "$work/stderr")>}"
    if [[ $rebuilt_ok -eq 1 ]]; then
      # Compare path<TAB>sha256 between the indexes; a line present in only one of them drifted.
      cut -f1,4 "$dir/index.tsv" | sort >"$work/old"
      cut -f1,4 "$fresh/index.tsv" | sort >"$work/new"
      comm -3 "$work/old" "$work/new" | sed 's/^[[:space:]]*//' | cut -f1 | sort -u | sed 's/^/drifted=/'
      [[ "$live_plan" == "$recorded_plan" ]] ||
        printf 'drifted=plan:%s\n' "$(meta_value plan_source "$dir/meta.env")"
    fi
  fi
  chmod -R u+w "$work"
  rm -rf "${work:?}"
  exit "$status"
}

cmd="${1:-}"
shift || true
case "$cmd" in
  build) build "$@" ;;
  verify) verify "$@" ;;
  -h | --help | help) usage ;;
  *) usage >&2; exit 2 ;;
esac
