---
name: gitignore-glob-dotdirectories
category: version-control
description: When `*.local` catches `.local`: use `!.local/` negation.
---

Shell-style glob patterns like `*.local` match dotdirectories (`.local/`) not just files, because `*` matches any characters. A pattern meant to ignore scratch files (`notes.local`) also hides `~/.local/` and `~/.[name]/` directories.

Fix by adding a negation pattern immediately after: `*.local` followed by `!.local/`. The negation re-includes the directory by name while files matching `*.local` remain ignored.

Check with `git check-ignore -v path` to see which rule is catching an unexpected file or directory.