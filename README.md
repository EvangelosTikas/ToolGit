# ToolGit 

![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/EvangelosTikas/ToolGit/.github/workflows/ci.yml)

An all-around toolkit for Git. 
*Everything* to assist you on your Git experience.
Everything is easier with a  few commands, ready to port anywhere at any time, for any environment (soon to be tested)
and for any user-level.


**Git Helpers**

A complete toolkit of bash helper functions for advanced git workflows:
- safe fetching, rebasing, merging
- finding and removing stale branches (local without remote, remote without local)
- comparing local vs remote branch commit hashes
- searching commits by sha / message / file diffs
- help/list resolving conflicts
- rescue detached HEAD

## Installation

  **Option 1: Quick install (no root required)**
  ```
  curl -fsSL https://github.com/EvangelosTikas/ToolGit/releases/tag/v0.0.1 | bash
  ```
  (TODO: *To be tested*)
  
  **Option 2: Make it executable and source it**
  ```
  git clone https://github.com/EvangelosTikas/ToolGit.git
  # cp git-helpers.sh ~/bin/git-helpers.sh
  chmod +x ~/bin/git-helpers.sh
  source /bin/git-helpers.sh
  ```
  
  ### Install Test tools

  For testing you will need `shellcheck` for linting the bash files which invoke the git functions. For unit-testing you will need
  `bats`. In Linux both can be installed when called (if not previously installed). 
  The snipet below serves a Unix installation example.
  ```[Linux]
  git clone --depth 1 https://github.com/bats-core/bats-core.git
  sudo ./bats-core/install.sh /usr/local
  ```
  Also use shellcheck online : [shellcheck](https://www.shellcheck.net/)
  Bats Instalation manual : [bats_core.readthedocs](https://bats-core.readthedocs.io/en/stable/installation.html).
  
  
## Usage (interactive via sourcing)

  ```
  source ~/bin/git-helpers.sh
  gh_help
  ```

## Testing 
  Requires bats and shellcheck.

  [Lint test]
  ```
  shellcheck bin/git_helpers.sh 
  ```

  [Bats smoke test]
  ```
  bats tests/test_bat.bats  
  ```
  
## Common examples
  #### dry-run a smart pull with rebase for the current branch:
  gh_smart_pull --rebase --dry

  #### actually delete remote branches that have no local counterpart:
  gh_delete_remote_branches_without_local --run

  #### compare hashes
  gh_compare_hashes feature/xyz origin

  #### search commits by message
  gh_search_commits --grep 'fix bug' 

  #### rescue detached HEAD and checkout:
  gh_rescue_detached_head temp-rescue --checkout
