---
name: quickshell-testing-command-mocking
description: Use when refactoring Quickshell code that calls commands.
category: testing
---

Mock every external tool the code invokes (brightnessctl, hyprctl, gsettings, systemctl, kill, nmcli, df, nvidia-smi, etc.) with a recording stub script. Each stub writes the call atomically in one write (to avoid interleaving with parallel calls), returns scripted output and exit codes, and writes state files if needed.

Run test scenarios through both today's code and the candidate using the same stub set. Collect and compare for every scenario:
- Every command call and its arguments
- All log lines (INFO, WARN)
- State written to files (hashes or full content)
- Exit codes

Test both success and failure paths: normal output, error output, missing tools, invalid inputs, refused operations, retries.

Use offscreen rendering and isolation: `QT_QPA_PLATFORM=offscreen`, scratch `XDG_CONFIG_HOME`, scratch `PATH` containing only the stubs. Run real services in both shells to exercise the code paths. Verify afterward that real system state (brightness, refresh rate, GTK theme, wallpaper, Wi-Fi) was unaffected.