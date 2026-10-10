# Programmatic config data extraction from external sources

Instead of manually copying or typing config data, extract from the authoritative source, validate, and apply atomically.

## Example: Terminal colours from TOML palettes

The episode needed to populate each shell theme palette with 16 ANSI terminal colours. Rather than hand-typing them:

1. **Extract** from official sources:
   - tokyonight: `~/.local/share/nvim/lazy/tokyonight.nvim/extras/alacritty/*.toml` (from the installed plugin)
   - catppuccin: fetched from `catppuccin/alacritty` GitHub repo

2. **Transform** into the target format:
   ```python
   import tomllib
   colors = tomllib.load(open(path, "rb"))["colors"]
   order = ["black", "red", "green", "yellow", "blue", "magenta", "cyan", "white"]
   term_array = (
       [colors["normal"][k].lower() for k in order] +
       [colors["bright"][k].lower() for k in order]
   )
   ```

3. **Validate** before applying:
   - Check all five palettes define the same keys in same order
   - Verify tokyo-night's 16 colours equal the user's existing `alacritty/themes/tokyonight-night.toml`
   - Verify palette `bg` and `text` equal that file's primary colors

4. **Apply atomically**:
   ```python
   tmp = os.path.join(os.path.dirname(dst), ".Themes.qml.new")
   with open(tmp, "w") as f:
       f.write(new_content); f.flush(); os.fsync(f.fileno())
   os.replace(tmp, dst)  # atomic swap: one filesystem operation
   ```

5. **Verify the consumer** picked up the change:
   - Check inotify watch: `grep "ino:$inode_hex " /proc/$pid/fdinfo/*`
   - Check reload logs: `journalctl | grep "Configuration Loaded"`
   - No warnings or errors

## Why atomic?

If a process watches the file with inotify or polls its inode, a partial write leaves it seeing inconsistent data. `os.replace()` is one atomic filesystem operation — the file either doesn't exist or exists with all new content, never halfway through.

## When to use

- Syncing config with external theme libraries (colours, icons, fonts)
- Populating API specifications or data structures from upstream docs
- Any config that must stay in sync with a canonical source and is watched by a running process
