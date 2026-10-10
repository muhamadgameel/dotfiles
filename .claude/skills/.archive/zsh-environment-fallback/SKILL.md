---
name: zsh-environment-fallback
category: config
description: "When configuring zsh in uwsm: export VAR=${VAR:-default}."
---

When the session (uwsm) provides default app variables (EDITOR, VISUAL, TERMINAL, PAGER), the shell should provide fallbacks for console/SSH contexts without overriding the session's values.

Use the pattern:

```bash
export EDITOR=${EDITOR:-nvim}
```

This pattern:
- Exports EDITOR so child processes inherit it.
- Uses the session's value if already set.
- Falls back to the default (nvim) if not set (console, SSH, macOS).

Avoid the anti-pattern `: ${EDITOR:=value}`, which sets the variable but doesn't export it. Child processes won't see it.

Test across contexts: console (nothing set), graphical session (all vars set), override (e.g., EDITOR=zed), and child process visibility.