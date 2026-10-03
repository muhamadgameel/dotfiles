# git

The global git config: settings and aliases in `.gitconfig`, plus
`~/.config/git/attributes` and `~/.config/git/ignore`. Settings for one machine,
such as a work identity or a proxy, go in `~/.gitconfig.local`, which
`.gitconfig` includes when it exists.

## What it changes

- Commits and tags are GPG-signed.
- `git pull` rebases. A rebase stashes uncommitted work first, applies
  `fixup!` commits, and moves stacked branches along with it.
- `git push` pushes the current branch, sets its upstream the first time, and
  sends tags that point at pushed commits.
- `git fetch` fetches every remote in parallel and prunes branches and tags
  that were deleted upstream.
- Conflicts show the common ancestor (`zdiff3`), and rerere replays
  resolutions you have made before.
- Diffs use the histogram algorithm, colour moved lines and detect copies.
  nvimdiff is the diff and merge tool.
- GitHub remotes cloned over HTTPS push over SSH. HTTPS credentials come from
  the keyring (libsecret).
- fsmonitor and the untracked cache keep `git status` fast in large repos.
- Branch lists sort by last commit, tag lists by version.
- `attributes` puts function names in diff hunk headers for C, Go, Python,
  Rust, TypeScript, Lua and more, and collapses lockfiles in diffs.
- `ignore` covers OS and editor clutter, local environment files, caches and
  logs, and scratch files (`scratch/`, `*.local`).

## Aliases

`git aliases` lists them all. Several use `dbr`, which finds origin's default
branch (main, master, trunk or develop) even when `origin/HEAD` is unset.

### Status and branches

| Alias | Does |
|---|---|
| `s`, `st` | Short status with the branch line. |
| `root` | Path of the repository's top directory. |
| `sha` | Short hash of HEAD. |
| `dbr` | Name of origin's default branch. |
| `sw`, `sc` | `switch`, and `switch -c` to create a branch. |
| `br` | Branches with their upstreams. |
| `recent` | Branches by last commit, with their subject lines. |
| `home` | Switch to the default branch. |

### Committing and undoing

| Alias | Does |
|---|---|
| `ci`, `cm` | `commit`, `commit -m`. |
| `ca`, `can` | Amend; amend without editing the message. |
| `fixup <sha>`, `squash <sha>` | Make a `fixup!` or `squash!` commit; `git ri <sha>~1` folds it in. |
| `wip`, `unwip` | Commit everything as `WIP`, skipping hooks; undo that commit if HEAD is one. |
| `undo` | Drop the last commit and keep its changes staged. |
| `uncommit` | Drop the last commit and keep its changes unstaged. |
| `unstage <path>`, `discard <path>` | `restore --staged`; `restore`. |
| `nevermind` | Throw away all uncommitted work and untracked files. Destructive. |

### Diffs and history

| Alias | Does |
|---|---|
| `d`, `ds`, `dw` | Diff; staged diff; word diff. |
| `dt` | `difftool` (nvimdiff). |
| `dbranch` | Everything this branch changed against the default branch. |
| `changed`, `changed-branch` | Changed file names, in the working tree or on this branch. |
| `l`, `lg`, `lga` | Graph log, one line per commit; `lga` includes every branch. |
| `last` | The last commit with its file stats. |
| `unmerged` | Commits on this branch that aren't on the default branch. |
| `standup` | Your commits since yesterday, across all branches. |
| `filelog <path>` | Full history of one file, following renames. |
| `bl <path>` | Blame that ignores whitespace and moved code, and honours `.git-blame-ignore-revs`. |
| `who`, `contributors` | Commit counts per author; `contributors` includes every branch. |

### Rebasing and pushing

| Alias | Does |
|---|---|
| `ri <base>` | Interactive rebase that folds in `fixup!` and `squash!` commits. |
| `rc`, `ra`, `rs` | Continue, abort or skip a rebase. |
| `sync` | Fetch every remote, then rebase onto the upstream. |
| `update` | Fetch origin, then rebase onto its default branch. |
| `p` | `push`. |
| `pf` | Force-push, but only if the remote hasn't moved since your last fetch. |

### Everything else

| Alias | Does |
|---|---|
| `sta`, `stash-all` | Stash, untracked files included. |
| `stl`, `stp`, `sts` | List stashes; pop; show a stash's patch. |
| `wt`, `wtl`, `wta`, `wtr` | `worktree`, and its list, add and remove. |
| `g <pattern>` | `grep`, grouped by file. |
| `f <pattern>` | Tracked files whose path matches. |
| `bs`, `bgood`, `bbad`, `breset` | Start, mark and reset a bisect. |
| `cleanup` | Delete local branches already merged into the default branch. |
| `gone`, `prune-gone` | List, or delete, branches whose upstream was deleted. |
| `aliases` | List every alias. |
