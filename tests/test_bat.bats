#!/usr/bin/env bats

# -----------------------------------------------------------------------------
# git_helpers.bats
# Integration tests for /bin/git_helpers.sh functions
# -----------------------------------------------------------------------------



# Load the helpers script once for all tests
setup_file() {

  # Compute absolute path to the script and source it once.
  SCRIPT_PATH="$(cd "$BATS_TEST_DIRNAME/.." && pwd)/bin/git_helpers.sh"
  echo "SETUP_FILE: sourcing git-helpers from: $SCRIPT_PATH" >&2
  [ -f "$SCRIPT_PATH" ] || { echo "ERROR: bin/git_helpers.sh not found at $SCRIPT_PATH" >&2; exit 1; }
  # shellcheck source=/dev/null
  source "$SCRIPT_PATH"
}

# Each test gets its own repo
setup() {
  # Setup the file
  setup_file

  TEST_ROOT=$(mktemp -d /tmp/git-helpers-test.XXXXXX)
  cd "$TEST_ROOT" || exit 1

  git init -q -b main
  git config user.email "test@example.com"
  git config user.name "Test User"

  echo "hello" > file.txt
  git add file.txt
  git commit -m "init commit" >/dev/null 2>&1

  REMOTE_DIR="$TEST_ROOT/remote.git"
  git init -q --bare "$REMOTE_DIR"

  git remote add origin "$REMOTE_DIR"

  # 👇 push quietly, discard stdout + stderr so it never pollutes test runs
  git push -u origin main >/dev/null 2>&1 || true


}

teardown() {
  cd /
  if [[ -n "${TEST_ROOT:-}" && -d "$TEST_ROOT" ]]; then
    rm -rf "$TEST_ROOT"
  fi
}

debug_run() {
  echo "Parent: $PROJECT_ROOT" >&3
  echo ">>> Running: $*"
  run "$@"
  echo ">>> Exit status: $status"
  echo ">>> Output:"
  printf '%s\n' "$output"
}

# -----------------------------------------------------------------------------
# Tests
# -----------------------------------------------------------------------------

@test "gh_help lists available commands" {
  debug_run gh_help
  [ "$status" -eq 0 ]
  [[ "$output" == *"gh_fetch_rebase_remote"* ]]
}

@test "gh_compare_hashes reports up-to-date local and remote" {
  run gh_compare_hashes main origin
  [ "$status" -eq 0 ]
  [[ "$output" == *"OK: local and remote match."* ]]
}

@test "gh_fetch_rebase_remote dry-run works" {
  run gh_fetch_rebase_remote main --dry
  [ "$status" -eq 0 ]
  [[ "$output" == *"Fetching remote"* ]]
  [[ "$output" == *"[dry-run] git rebase origin/main"* ]]
}

@test "gh_smart_pull detects detached HEAD" {

  git checkout HEAD^ >/dev/null 2>&1 || skip "need at least 2 commits"
  echo "hello second time" > file2.txt
  git add file2.txt
  git commit -m "file2 commit" >/dev/null 2>&1
  git push -u origin main >/dev/null 2>&1 || true

  run gh_smart_pull --dry
  [ "$status" -ne 0 ]
  [[ "$output" == *"HEAD is detached"* ]]
}

@test "gh_delete_local_branches_without_remote finds nothing initially" {
  run gh_delete_local_branches_without_remote --dry
  [ "$status" -eq 0 ]
  [[ "$output" == *"No local branches"* ]]
}

@test "gh_rescue_detached_head creates rescue branch" {
  git checkout --detach >/dev/null 2>&1
  run gh_rescue_detached_head rescue-test
  [ "$status" -eq 0 ]
  [[ "$output" == *"Branch created."* ]]
}

@test "gh_search_commits by message finds init commit" {
  run gh_search_commits --grep init
  [ "$status" -eq 0 ]
  [[ "$output" == *"init commit"* ]]
}
