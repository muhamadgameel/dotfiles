---
name: quickshell-offscreen-visual-testing
category: testing
description: Use when testing Quickshell UI: render offscreen to PNG.
---

Launch the shell with `QT_QPA_PLATFORM=offscreen`. Components render with real fonts, cleanly and invisibly.

To inspect: `item.grabToImage(result => result.saveToFile(path), Qt.size(w * 3, h * 3))` saves a 3x-scaled PNG. Use it to compare icon choices, spacing, and layout variants before writing live edits.
