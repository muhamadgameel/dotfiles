python3 - "$S/themes/Themes.qml" "$Q/core/Themes.qml" <<'EOF'
...
with open(tmp, "w") as f:
    f.write(open(src).read()); f.flush(); os.fsync(f.fileno())
os.replace(tmp, dst)   # one atomic swap: the shell never sees a half-written file
...
catppuccin-mocha       18 keys, term has 16 colours, equal to the official theme: True
catppuccin-macchiato   18 keys, term has 16 colours, equal to the official theme: True
catppuccin-latte       18 keys, term has 16 colours, equal to the official theme: True
tokyo-night            18 keys, term has 16 colours, equal to the official theme: True
tokyo-night-storm      18 keys, term has 16 colours, equal to the official theme: True
...
tokyo-night term equals your Alacritty theme's 16 colours: True
palette bg/text equal your terminal's background/foreground: True