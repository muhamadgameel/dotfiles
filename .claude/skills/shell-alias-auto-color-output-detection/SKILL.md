---
name: shell-alias-auto-color-output-detection
description: Use when ls pipes show escape codes: use --color=auto.
category: shell-config
---

When aliasing `ls` or `eza`, do not force `--color=always` or `--icons=always`. Instead, use `--color=auto` and `--icons=auto` to let the tool detect whether it is writing to a terminal, a pipe, or a file. Piped output and redirects should never carry escape codes or icon glyphs.

## The problem

If you alias `ls='ls --color=always'` or `eza --color=always --icons=always`, then `ls | grep` and `ls > file` both output escape codes and icon bytes, which corrupt grep patterns and bloat files with non-text garbage.

## The solution

```zsh
alias ls="eza --icons=auto --smart-group"
alias ll="ls --long"
alias la="ls --all"
alias lla="ls --long --all"
```

For the fallback without eza:

```zsh
case $_os in
  Darwin) alias ls="ls -hG" ;;
  Linux)  alias ls="ls -h --color=auto" ;;
esac
```

Both `--color=auto` (GNU ls) and `--icons=auto` (eza) default to colour and icons on a terminal, no formatting in pipes, and no glyphs in files.

## Preview and interactive tools

An exception: interactive tools like fzf and fzf-tab previews do live in a pane and benefit from forced formatting, so keep `--color=always` there.
