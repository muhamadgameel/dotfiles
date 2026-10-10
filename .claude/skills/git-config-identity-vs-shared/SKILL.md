---
name: git-config-identity-vs-shared
description: When git config --global hits the repo: keep identity local.
category: git-workflow
---

Identity (name, email, signing key) lives in a local `~/.gitconfig` outside
version control. Shared settings (aliases, behavior, diff drivers) are tracked
in `~/.config/git/config`.

When you run `git config --global`, `gh auth setup-git`, or `git lfs install`,
they write to the local file, not the repo. Git reads both files with the local
one last, so it also serves as the per-machine override layer.

**To migrate** from a tracked `.gitconfig` that held everything: extract the
`[user]` block into a new local `~/.gitconfig`, then remove `[user]` and any
`[include]` sections from the tracked copy. If `~/.gitconfig.local` exists,
merge its settings into the new file and delete .local. Remove the old tracked
file and any symlink.

Verify with `git config --list --show-origin` — identity should come from
`~/.gitconfig`, everything else from the XDG file. A test `git config --global`
write should land in the local file, not the repo.