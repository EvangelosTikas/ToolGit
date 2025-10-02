# ToolGit
A toolkit for Git, everything to assist you on your Git experience.
Everything is easier witha  few commands, ready to port anywhere at any time, any environment (soon to be tested)
and any user-level.


## git-helpers

A complete toolkit of bash helper functions for advanced git workflows:
- safe fetching, rebasing, merging
- finding and removing stale branches (local without remote, remote without local)
- comparing local vs remote branch commit hashes
- searching commits by sha / message / file diffs
- help/list resolving conflicts
- rescue detached HEAD

## Installation

  ### Make executable and put in PATH
  ```
  cp git-helpers.sh ~/bin/git-helpers.sh
  chmod +x ~/bin/git-helpers.sh
  ```

## Usage (interactive via sourcing)

  ```
  source ~/bin/git-helpers.sh
  gh_help
  ```

Common examples
  # dry-run a smart pull with rebase for the current branch:
  gh_smart_pull --rebase --dry

  # actually delete remote branches that have no local counterpart:
  gh_delete_remote_branches_without_local --run

  # compare hashes
  gh_compare_hashes feature/xyz origin

  # search commits by message
  gh_search_commits --grep 'fix bug' 

  # rescue detached HEAD and checkout:
  gh_rescue_detached_head temp-rescue --checkout
