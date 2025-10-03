#!/usr/bin/env bats

# -----------------------------------------------------------------------------
# git_helpers.bats
# Integration tests for /bin/git_helpers.sh functions
# -----------------------------------------------------------------------------



# Load the helpers script once for all tests
setup_file() {
  SOURCE_DIR="$(dirname "$BASH_SOURCE")"
  BATS_TEST_DIRNAME="$(git rev-parse --show-toplevel)"
  source "$BATS_TEST_DIRNAME/bin/git_helpers.sh"
}

# Each test gets its own repo
setup() {
  # Create isolated temporary root for each test
  TEST_ROOT=$(mktemp -d /tmp/git-helpers-test.XXXXXX)
  cd "$TEST_ROOT"

  # Create repo + remote
  git init -q
  echo "hello" > file.txt
  git add file.txt
  git commit -m "init commit" >/dev/null
  git branch -M main

  REMOTE_DIR="$TEST_ROOT/remote.git"
  git init --bare "$REMOTE_DIR" >/dev/null
  git remote add origin "$REMOTE_DIR"
  git push -u origin main >/dev/null
}

teardown() {
  cd /
  if [[ -n "${TEST_ROOT:-}" && -d "$TEST_ROOT" ]]; then
    rm -rf "$TEST_ROOT"
  fi
}

# -----------------------------------------------------------------------------
# Tests
# -----------------------------------------------------------------------------

@test "gh_help lists available commands" {
  run gh_help
  [ "$status" -eq 0 ]
  [[ "$output" == *"gh_smart_pull"* ]]
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
