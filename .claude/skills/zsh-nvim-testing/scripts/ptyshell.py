#!/usr/bin/env python3
"""ptyshell.py - drive an interactive program in a pty and read what it prints.

As a command, an interactive zsh that cannot touch the real history, caches or
zoxide data; each argument is typed, Enter is pressed, and the output is printed:

    ptyshell.py 'echo $ZSH_CONF_DIR' 'alias ls'
    ZDOTDIR=/scratch/zsh-copy ptyshell.py 'echo $ZSH_CONF_DIR'     # another copy of the config

As a module:

    from ptyshell import Pty, isolated_env
    sh = Pty(["zsh", "-i"], env=isolated_env("/scratch/dir"))
    sh.read()                       # everything up to the first quiet moment
    sh.send("ls\\t")                # keys: \\t Tab, \\r Enter, \\x03 Ctrl+C, \\x15 kill line
    print(sh.read())
    sh.close()
"""
import fcntl
import os
import pty
import re
import select
import signal
import struct
import sys
import tempfile
import termios
import time

ANSI = re.compile(r"\x1b\[[0-9;?<>=]*[ -/]*[@-~]|\x1b\][^\x07\x1b]*(\x07|\x1b\\)|\x1b[()][A-Z0-9]|\x1b[=>]|\r")


def isolated_env(scratch):
    """The real config, with every file the shell writes moved under scratch."""
    env = dict(os.environ, TERM="xterm-256color")
    env.update(XDG_CACHE_HOME=f"{scratch}/cache", XDG_STATE_HOME=f"{scratch}/state", _ZO_DATA_DIR=f"{scratch}/zoxide")
    for key in ("XDG_CACHE_HOME", "XDG_STATE_HOME", "_ZO_DATA_DIR"):
        os.makedirs(env[key], exist_ok=True)
    return env


class Pty:
    def __init__(self, argv, env=None, rows=40, cols=120, cwd=None):
        self.pid, self.fd = pty.fork()
        if self.pid == 0:
            fcntl.ioctl(0, termios.TIOCSWINSZ, struct.pack("HHHH", rows, cols, 0, 0))
            if cwd:
                os.chdir(cwd)
            os.execvpe(argv[0], argv, env or os.environ)

    def send(self, keys):
        os.write(self.fd, keys.encode())

    def read(self, quiet=0.6, limit=15, raw=False):
        """Read until nothing has arrived for `quiet` seconds, at most `limit` seconds."""
        out, end, last = b"", time.monotonic() + limit, time.monotonic()
        while time.monotonic() < end and time.monotonic() - last < quiet:
            if not select.select([self.fd], [], [], 0.05)[0]:
                continue
            try:
                chunk = os.read(self.fd, 65536)
            except OSError:
                break
            if not chunk:
                break
            out, last = out + chunk, time.monotonic()
            # Play the terminal: zoxide's completion and fzf wait for these answers.
            if b"\x1b[5n" in chunk:
                os.write(self.fd, b"\x1b[0n")
            if b"\x1b[6n" in chunk:
                os.write(self.fd, b"\x1b[1;1R")
        text = out.decode(errors="replace")
        return text if raw else ANSI.sub("", text)

    def close(self, wait=2):
        """Never block on a program that swallows keys: ask, then hang up, then kill."""
        for sig in (None, signal.SIGHUP, signal.SIGKILL):
            if sig:
                try:
                    os.kill(self.pid, sig)
                except ProcessLookupError:
                    break
            end = time.monotonic() + wait
            while time.monotonic() < end:
                if os.waitpid(self.pid, os.WNOHANG)[0]:
                    os.close(self.fd)
                    return
                time.sleep(0.05)
        os.close(self.fd)


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    with tempfile.TemporaryDirectory(prefix="ptyshell-") as scratch:
        sh = Pty(["zsh", "-i"], env=isolated_env(scratch))
        sh.read(quiet=1.5)
        # Without this zsh prints a "%" marker line that lands in every capture.
        sh.send(" unsetopt prompt_sp\r")
        sh.read()
        for line in sys.argv[1:]:
            sh.send(f" {line}\r")
            print(f"$ {line}\n{sh.read().strip()}\n")
        sh.send(" exit\r")
        sh.close()


if __name__ == "__main__":
    main()
