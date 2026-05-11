#!/usr/bin/env bash
# statusline-bar test runner
# Usage:
#   test/run-tests.sh                  # run all
#   test/run-tests.sh --filter PATTERN # only matching ids
#   test/run-tests.sh --update         # regenerate test/expected/*.out (asks confirm)

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SCRIPT="$REPO_DIR/statusline-bar.sh"
EXPECTED_DIR="$SCRIPT_DIR/expected"
ACTUAL_DIR="$SCRIPT_DIR/actual"
FIXTURES_DIR="$SCRIPT_DIR/fixtures"
CONFIGS_DIR="$SCRIPT_DIR/configs"

mkdir -p "$ACTUAL_DIR"

# The synthetic workspace dir referenced by fixtures/sample-input.json. Several
# tests need it to exist so token render functions can cd into it. The mock
# git binary on PATH handles the rest.
mkdir -p /tmp/statusline-bar-test

# Prepend test/bin to PATH for mocks (git, etc).
export PATH="$SCRIPT_DIR/bin:$PATH"

FILTER=""
UPDATE=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --filter) FILTER="$2"; shift 2 ;;
    --update) UPDATE=1; shift ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

PASS=0
FAIL=0
FAILED_IDS=()

# Run one test case.
#   $1 = case id (e.g. "preset_default")
#   $2 = fixture filename in fixtures/ (or empty for no stdin)
#   $3 = config filename in configs/ (or empty for built-in defaults)
#   $4+ = extra CLI args
run_case() {
  local id="$1" fixture="$2" config="$3"
  shift 3
  if [[ -n "$FILTER" && "$id" != *"$FILTER"* ]]; then
    return
  fi
  local args=()
  if [[ -n "$config" ]]; then
    args+=(--config "$CONFIGS_DIR/$config")
  fi
  args+=("$@")
  local actual_path="$ACTUAL_DIR/$id.out"
  local expected_path="$EXPECTED_DIR/$id.out"
  local stdin_src=/dev/null
  if [[ -n "$fixture" ]]; then
    if [[ -f "$FIXTURES_DIR/$fixture" ]]; then stdin_src="$FIXTURES_DIR/$fixture"
    elif [[ -f "$SCRIPT_DIR/$fixture" ]]; then stdin_src="$SCRIPT_DIR/$fixture"
    else echo "FAIL $id (fixture not found: $fixture)"; FAIL=$((FAIL+1)); FAILED_IDS+=("$id"); return
    fi
  fi
  # Per-case pre-hook (optional)
  local pre_fn="pre_${id}"
  if declare -F "$pre_fn" >/dev/null; then "$pre_fn"; fi
  # CASE_ENV lets a case override env vars; falls back to NO_COLOR=1
  local env_prefix="${CASE_ENV:-NO_COLOR=1}"
  # expect_exit_<id> lets a case assert a non-zero exit code (default 0)
  local exit_var="expect_exit_${id}"
  local expected_exit="${!exit_var:-0}"
  local actual_exit=0
  if /usr/bin/env $env_prefix "$SCRIPT" "${args[@]}" < "$stdin_src" > "$actual_path" 2>&1; then
    actual_exit=0
  else
    actual_exit=$?
  fi
  if [[ "$actual_exit" != "$expected_exit" ]]; then
    echo "FAIL $id (exit $actual_exit; expected $expected_exit)"
    FAIL=$((FAIL+1))
    FAILED_IDS+=("$id")
    return
  fi
  if (( UPDATE )); then
    cp "$actual_path" "$expected_path"
    echo "UPDATED $id"
    return
  fi
  if [[ ! -f "$expected_path" ]]; then
    echo "FAIL $id (no expected: $expected_path)"
    FAIL=$((FAIL+1))
    FAILED_IDS+=("$id")
    return
  fi
  if diff -u "$expected_path" "$actual_path" > /dev/null; then
    # Run post-hook if defined; it can FAIL the case.
    local post_fn="post_${id}"
    if declare -F "$post_fn" >/dev/null; then
      local post_out
      if ! post_out="$("$post_fn")"; then
        echo "$post_out"
        FAIL=$((FAIL+1))
        FAILED_IDS+=("$id")
        return
      fi
    fi
    PASS=$((PASS+1))
  else
    echo "FAIL $id"
    diff -u "$expected_path" "$actual_path" | head -n 20 | sed 's/^/    /'
    FAIL=$((FAIL+1))
    FAILED_IDS+=("$id")
  fi
}

# Cases are registered by sourcing tests/cases.sh once it exists.
if [[ -f "$SCRIPT_DIR/cases.sh" ]]; then
  # shellcheck disable=SC1091
  . "$SCRIPT_DIR/cases.sh"
fi

echo ""
echo "passed: $PASS  failed: $FAIL"
if (( FAIL > 0 )); then
  echo "failed ids:"
  printf '  %s\n' "${FAILED_IDS[@]}"
  exit 1
fi
exit 0
