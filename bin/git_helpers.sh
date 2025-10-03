#!/usr/bin/env bash
#
# git-helpers.sh
# A collection of Bash functions for advanced git workflows:
# - safe merge/pull/fetch/rebase helpers
# - delete branches that don't exist locally/remotely (dry-run + confirm)
# - check remote vs local branch hashes
# - search commits by SHA, message, or file changes
# - assist with conflicts and rescue detached HEAD states
#
# Usage:
#   source /path/to/git-helpers.sh
#   gh_help               # show help and exported commands
#
# Author: Evangelos Tikas
# License: MIT

# ---------- Help ----------
# If script invoked directly, print help (see bottom down in this file)
printf "[\033[94mToolGit\033[0m]\n"
printf "[\033[94m <<< WELCOME! >>> \033[0m]\n"


# Safety gather any argument passed
collect_args () {
  arg1=${1:-""}
  echo "Arguments..."
  echo "$arg1"
}

echo_tg() {
  # INFO_MSG="[\e[94mMSG\e[0m]"
  # PASS_MSG="\e[91mPASS\e[0m\n"
  printf "[\033[94mToolGit\033[0m] %s\n" "$*"
}


# ---------- Utility helpers ----------
git_is_repo() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1
}

current_branch() {
  git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "(detached)"
}

get_current () {
  printf "[INFO] current branch.\n"
  current_branch
}


confirm() {
  # prompt for yes/no; returns 0 for yes
  local msg=${1:-"Are you sure?"}
  # local default=${2:-n}
  read -r -p "$msg [y/N]: " ans
  case "$ans" in
    y|Y|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}


abort_if_not_repo() {
  if ! git_is_repo; then
    echo "ERROR: not a git repository (or no git installed)." >&2
    return 1
  fi
}

dry_run_or_exec() {
  # Usage: dry_run_or_exec "$DRY" "command to run as string"
  local dry=${1:-true}
  local cmd=${2:-}
  if [[ "$dry" == "true" ]]; then
    echo "[dry-run] $cmd"
  else
    eval "$cmd"
  fi
}

# ---------- git helpers ----------
gh_help() {

  echo_tg "A list for ToolGit usage...!\n"

  cat <<'EOF'
git-helpers - available commands:

  gh_fetch_rebase_remote BRANCH [--dry]
  gh_smart_pull [--rebase] [--dry]
  gh_smart_merge TARGET_BRANCH [--no-ff] [--dry]
  gh_delete_local_branches_without_remote [--dry] [--force]
  gh_delete_remote_branches_without_local [--dry] [--force]
  gh_compare_hashes BRANCH REMOTE [--remote-name=origin]
  gh_search_commits --sha <sha> | --grep <regex> | --file <path>
  gh_assist_conflicts        # lists conflicted files and common commands
  gh_rescue_detached_head NAME [--checkout]
  gh_delete_branch_safe NAME [--dry] [--force]   # deletes both local & remote safely

Examples:
  source ./git-helpers.sh
  gh_smart_pull --rebase --dry
  gh_compare_hashes feature/mybranch origin
EOF
}

# ---------- fetch + rebase helper ----------
gh_fetch_rebase_remote() {
  abort_if_not_repo || return 1
  local branch=${1:-$(current_branch)}
  local dry="true"
  shift || true
  for a in "$@"; do
    [[ "$a" == "--dry" ]] && dry="true"
    [[ "$a" == "--run" ]] && dry="false"
  done

  local remote=${REMOTE:-origin}
  echo "Fetching remote '$remote'..."
  dry_run_or_exec "$dry" "git fetch --prune $remote"

  echo "Attempting to rebase local '$branch' onto '$remote/$branch' (if exists)..."
  # check remote hash
  local remote_hash
  remote_hash=$(git ls-remote "$remote" "refs/heads/$branch" | awk '{print $1}' || true)
  if [[ -z "$remote_hash" ]]; then
    echo "No remote branch '$remote/$branch' found. Aborting rebase."
    return 2
  fi

  dry_run_or_exec "$dry" "git rebase $remote/$branch"
  echo "Done."
}

# ---------- smart pull (fetch + merge or rebase) ----------
gh_smart_pull() {
  abort_if_not_repo || return 1
  local dry="true"
  local use_rebase="false"
  for a in "$@"; do
    case "$a" in
      --rebase) use_rebase="true" ;;
      --dry) dry="true" ;;
      --run) dry="false" ;;
      *) ;;
    esac
  done

  local branch
  branch=$(current_branch)
  if [[ "$branch" == "(detached)" ]]; then
    echo "WARNING: HEAD is detached. Use gh_rescue_detached_head first." >&2
    return 2
  fi

  local remote=origin
  echo "Fetching $remote..."
  dry_run_or_exec "$dry" "git fetch --prune $remote"

  if [[ "$use_rebase" == "true" ]]; then
    echo "Rebasing '$branch' on $remote/$branch"
    dry_run_or_exec "$dry" "git rebase $remote/$branch"
  else
    echo "Merging $remote/$branch into $branch (fast-forward allowed)"
    dry_run_or_exec "$dry" "git merge --ff-only $remote/$branch || git merge $remote/$branch"
  fi
}

# ---------- smart merge ----------
gh_smart_merge() {
  abort_if_not_repo || return 1
  local target=${1:-}
  if [[ -z "$target" ]]; then
    echo "Usage: gh_smart_merge TARGET_BRANCH [--no-ff] [--dry|--run]" >&2
    return 1
  fi
  local noff="false"
  local dry="true"
  shift
  for a in "$@"; do
    [[ "$a" == "--no-ff" ]] && noff="true"
    [[ "$a" == "--dry" ]] && dry="true"
    [[ "$a" == "--run" ]] && dry="false"
  done

  local current
  current=$(current_branch)
  if [[ "$current" == "(detached)" ]]; then
    echo "Cannot merge while detached HEAD. Use gh_rescue_detached_head." >&2
    return 2
  fi

  # fetch remote branch if any
  dry_run_or_exec "$dry" "git fetch --prune"
  if [[ "$noff" == "true" ]]; then
    dry_run_or_exec "$dry" "git merge --no-ff $target"
  else
    dry_run_or_exec "$dry" "git merge $target"
  fi
}

# ---------- delete branches helpers ----------
gh_delete_local_branches_without_remote() {
  abort_if_not_repo || return 1
  local dry="true"
  local force="false"
  for a in "$@"; do
    [[ "$a" == "--dry" ]] && dry="true"
    [[ "$a" == "--run" ]] && dry="false"
    [[ "$a" == "--force" ]] && force="true"
  done

  git fetch --prune >/dev/null 2>&1 || true

  local branches
  branches=$(git for-each-ref --format='%(refname:short) %(upstream:short)' refs/heads/)

  echo "Local branches without upstream remote:"
  local to_delete=()
  while read -r line; do
    [[ -z "$line" ]] && continue
    local local_branch
    local upstream
    local_branch=$(awk '{print $1}' <<<"$line")
    upstream=$(awk '{print $2}' <<<"$line" || true)
    if [[ -z "$upstream" ]]; then
      # no upstream defined — check if remote branch exists with same name
      if ! git ls-remote --heads origin "refs/heads/$local_branch" | grep -q .; then
        echo "  - $local_branch"
        to_delete+=("$local_branch")
      fi
    fi
  done <<<"$branches"

  if [[ "${#to_delete[@]}" -eq 0 ]]; then
    echo "No local branches that appear to be orphaned from remote."
    return 0
  fi

  echo
  echo "Branches to delete (local): ${to_delete[*]}"
  if [[ "$dry" == "true" ]]; then
    echo "Dry-run enabled. Use --run to actually delete."
    return 0
  fi

  if ! confirm "Proceed to delete these local branches?"; then
    echo "Cancelled."
    return 1
  fi

  for b in "${to_delete[@]}"; do
    if [[ "$force" == "true" ]]; then
      git branch -D "$b"
    else
      git branch -d "$b" || {
        echo "Failed normal delete for $b, use --force to force delete."
      }
    fi
  done
}

gh_delete_remote_branches_without_local() {
  abort_if_not_repo || return 1
  local remote="origin"
  local dry="true"
  local force="false"
  for a in "$@"; do
    [[ "$a" == "--dry" ]] && dry="true"
    [[ "$a" == "--run" ]] && dry="false"
    [[ "$a" == "--force" ]] && force="true"
    [[ "$a" == --remote* ]] && remote="${a#--remote=}"
  done

  git fetch --prune "$remote" >/dev/null 2>&1 || true

  # list remote branches
  local remote_branches
  remote_branches=$(git for-each-ref --format='%(refname:short)' refs/remotes/"$remote"/ | sed "s|^$remote/||")

  local to_delete=()
  for rb in $remote_branches; do
    if ! git show-ref --verify --quiet "refs/heads/$rb"; then
      # no local branch by that name
      to_delete+=("$rb")
      echo "  - $remote/$rb (no local)"
    fi
  done

  if [[ "${#to_delete[@]}" -eq 0 ]]; then
    echo "No remote branches that lack a corresponding local branch."
    return 0
  fi

  echo
  echo "Remote branches to delete: ${to_delete[*]}"
  if [[ "$dry" == "true" ]]; then
    echo "Dry-run enabled. Use --run to actually delete remote branches."
    return 0
  fi

  if ! confirm "Proceed to delete these remote branches on $remote?"; then
    echo "Cancelled."
    return 1
  fi

  for rb in "${to_delete[@]}"; do
    if [[ "$force" == "true" ]]; then
      git push "$remote" --delete "$rb"
    else
      git push "$remote" --delete "$rb" || {
        echo "Failed to delete remote $remote/$rb"
      }
    fi
  done
}

# ---------- compare hashes ----------
gh_compare_hashes() {
  abort_if_not_repo || return 1
  local branch=${1:-$(current_branch)}
  local remote=${2:-origin}
  if [[ -z "$branch" ]]; then
    echo "Usage: gh_compare_hashes BRANCH [REMOTE]" >&2
    return 1
  fi

  local local_hash remote_hash
  local_hash=$(git rev-parse "refs/heads/$branch" 2>/dev/null || true)
  if [[ -z "$local_hash" ]]; then
    echo "Local branch '$branch' not found."
    return 2
  fi

  remote_hash=$(git ls-remote "$remote" "refs/heads/$branch" | awk '{print $1}' || true)
  if [[ -z "$remote_hash" ]]; then
    echo "Remote branch '$remote/$branch' not found."
  fi

  echo "Local:  $local_hash"
  echo "Remote: $remote_hash"

  if [[ "$local_hash" == "$remote_hash" ]]; then
    echo "OK: local and remote match."
  else
    echo "DIFFER: local and remote diverge."
    echo "Commits in local not in remote:"
    git log --oneline "$remote"/"$branch".."$branch" || true
    echo "Commits in remote not in local:"
    git log --oneline "$branch".."$remote"/"$branch" || true
  fi
}

# ---------- search commits ----------
gh_search_commits() {
  abort_if_not_repo || return 1
  if [[ $# -lt 2 ]]; then
    cat <<EOF
Usage:
  gh_search_commits --sha <sha>
  gh_search_commits --grep <regex>
  gh_search_commits --file <path>
  gh_search_commits --diff <pattern>

Examples:
  gh_search_commits --sha 1a2b3c
  gh_search_commits --grep 'fix.*bug'
  gh_search_commits --file src/app.js
  gh_search_commits --diff 'TODO'
EOF
    return 1
  fi

  case "$1" in
    --sha)
      local sha="$2"
      git show --pretty=fuller --no-patch "$sha" || echo "No commit $sha"
      ;;
    --grep)
      shift
      git log --all --pretty=oneline --grep="$*" -n 200
      ;;
    --file)
      local file="$2"
      git log --all --pretty=oneline -- "$file" | sed -n '1,200p'
      ;;
    --diff)
      shift
      local pattern="$*"
      # git log -S searches for added/removed string; -G for regex in patch
      git log --all -p -G"$pattern" --pretty=oneline | sed -n '1,500p'
      ;;
    *)
      echo "Unknown option $1" >&2
      return 2
      ;;
  esac
}

# ---------- assist with conflicts ----------
gh_assist_conflicts() {
  abort_if_not_repo || return 1
  # Show status and conflicting files
  echo "Git status:"
  git status --short
  echo

  local conflicts
  conflicts=$(git diff --name-only --diff-filter=U || true)
  if [[ -z "$conflicts" ]]; then
    echo "No merge conflicts detected."
    return 0
  fi

  echo "Conflicted files:"
  echo "$conflicts"
  echo

  cat <<'EOF'
Suggested next steps:
  - Inspect a file:        git diff <file>
  - Open mergetool:       git mergetool
  - Mark resolved:        git add <file>
  - Continue merge/rebase:
       git rebase --continue   OR   git merge --continue
  - Abort:
       git rebase --abort      OR   git merge --abort
  - To see conflict markers inline:
       grep -n '<<<<<<< ' -n <file>

Use gh_assist_conflicts after you ran a merge/rebase that produced conflicts.
EOF
}

# ---------- rescue detached HEAD ----------
gh_rescue_detached_head() {
  abort_if_not_repo || return 1
  local name=${1:-rescue-branch}
  local checkout="false"
  for a in "$@"; do
    [[ "$a" == "--checkout" ]] && checkout="true"
  done

  local head_sha
  head_sha=$(git rev-parse --verify HEAD)
  echo "Detected HEAD at $head_sha"

  if git rev-parse --verify "refs/heads/$name" >/dev/null 2>&1; then
    echo "Branch $name already exists."
    if [[ "$checkout" == "true" ]]; then
      git checkout "$name"
    fi
    return 0
  fi

  echo "Creating branch '$name' at $head_sha"
  git branch "$name" "$head_sha"
  if [[ "$checkout" == "true" ]]; then
    git checkout "$name"
  fi
  echo "Branch created. You may now push it: git push -u origin $name"
}

# ---------- safe delete both local & remote ----------
gh_delete_branch_safe() {
  abort_if_not_repo || return 1
  local name=${1:-}
  if [[ -z "$name" ]]; then
    echo "Usage: gh_delete_branch_safe NAME [--dry|--run] [--force]" >&2
    return 1
  fi
  local dry="true"
  local force="false"
  for a in "$@"; do
    [[ "$a" == "--run" ]] && dry="false"
    [[ "$a" == "--dry" ]] && dry="true"
    [[ "$a" == "--force" ]] && force="true"
  done

  echo "Local exists: $(git show-ref --verify --quiet "refs/heads/$name" && echo yes || echo no)"
  echo "Remote exists: $(git ls-remote --heads origin "refs/heads/$name" | awk '{print $1}' || true)"

  if [[ "$dry" == "true" ]]; then
    echo "Dry-run. use --run to actually delete. Use --force to force local deletion."
    return 0
  fi

  if [[ ! $(git show-ref --verify --quiet "refs/heads/$name"; echo $?) -eq 0 ]]; then
    echo "No local branch $name"
  else
    if [[ "$force" == "true" ]]; then
      git branch -D "$name"
    else
      git branch -d "$name" || {
        echo "Local branch not fully merged. Use --force"
        return 1
      }
    fi
  fi

  if git ls-remote --heads origin "refs/heads/$name" | grep -q .; then
    git push origin --delete "$name" || {
      echo "Failed to delete remote branch origin/$name"
      return 2
    }
  fi
  echo "Deleted branch $name locally and remotely (if they existed)."
}


# ---------- Check branch is up-to-date with remote ----------
gh_check_up_to_date() {
    # --- This is a function to check that your current_branch is up to date with the remote main branch (origin/main)
    # TODO: add remote branch option:$1 passed by user

    # Fetch the latest updates from the remote
    git fetch origin

    # Get the name of the current branch
    current_branch=$(git rev-parse --abbrev-ref HEAD)

    # Determine the main branch (either origin/main or origin/main)
    main_branch="origin/main"
    if git show-ref --verify --quiet refs/remotes/origin/main; then
        main_branch="origin/main"
    fi

    # Check if the current branch is up to date with origin/main or origin/main
    echo "Checking if $current_branch is up to date with $main_branch..."

    # Compare the branches
    up_to_date=$(git rev-list --count "${current_branch}".."${main_branch}")

    if [ "$up_to_date" -eq 0 ]; then
        echo "Your branch '$current_branch' is up-to-date with $main_branch."
    else
        echo "Your branch '$current_branch' is not up-to-date with $main_branch."
        echo "The following commits are missing from your branch:"

        # List the missing commits
        git log "${current_branch}".."${main_branch}" --oneline
    fi
}


# ---------- Bash completion for git-helpers ----------

_gh_completions() {
    local cur=${COMP_WORDS[COMP_CWORD]}
    local options=(
        gh_help gh_fetch_rebase_remote gh_smart_pull gh_smart_merge
        gh_delete_local_branches_without_remote gh_delete_remote_branches_without_local
        gh_compare_hashes gh_search_commits gh_assist_conflicts
        gh_rescue_detached_head gh_delete_branch_safe gh_check_up_to_date
    )

    mapfile -t COMPREPLY < <(compgen -W "${options[*]}" -- "$cur")
}

complete -F _gh_completions gh

# Optionally export functions for interactive shells (uncomment if desired)
# export -f gh_fetch_rebase_remote gh_smart_pull gh_smart_merge gh_delete_local_branches_without_remote gh_delete_remote_branches_without_local gh_compare_hashes gh_search_commits gh_assist_conflicts gh_rescue_detached_head gh_delete_branch_safe gh_help

# If script invoked directly, print help
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then

  set -o errexit
  set -o pipefail
  set -o nounset
  gh_help
fi


