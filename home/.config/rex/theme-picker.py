#!/usr/bin/env python3
"""fzf reports choices; one worker serializes real theme changes until the popup closes.

Enter settles on the selected preset. Escape or a terminal hangup settles on the
starting preset. In both cases the worker finishes before we remove its scratch files.
"""
from contextlib import contextmanager
import fcntl
import os
import re
import selectors
import signal
import subprocess
import sys
import tempfile
import threading
from pathlib import Path

HELPER = Path(__file__).resolve().with_name("apply-picker-theme.sh")
CONFIG = Path.home() / ".config"


class Preview(threading.Thread):
    def __init__(self, stage, original):
        super().__init__()
        self.stage = stage
        self.original = self.wanted = original
        self.condition = threading.Condition()
        self.finished = False
        self.error = None

    def highlight(self, name):
        self._request(name, final=False)

    def accept(self, name):
        self._request(name, final=True)

    def cancel(self):
        self._request(self.original, final=True)

    def _request(self, name, *, final):
        with self.condition:
            # Keep only the latest highlight. Replaying stale previews causes flicker.
            self.wanted, self.finished = name, final
            self.condition.notify()

    def apply(self, operation, name):
        # Closing a Rex pane sends a hangup to its terminal process group.
        # An in-flight write must finish before the worker restores the preset.
        subprocess.run(["/bin/bash", HELPER, operation, self.stage, name],
                       check=True, stdout=subprocess.DEVNULL, start_new_session=True)

    def run(self):
        current = self.original
        try:
            self.apply("prepare", current)
            while True:
                with self.condition:
                    self.condition.wait_for(lambda: self.finished or self.wanted != current)
                    target, done = self.wanted, self.finished
                if target != current:
                    current = target  # Restore even if a preview partially fails.
                    self.apply("preview", target)
                if done:
                    if target != self.original:
                        self.apply("commit", target)
                    return
        except Exception as exc:
            self.error = exc
            if current != self.original:
                try:
                    self.apply("preview", self.original)
                except Exception as restore_error:
                    print(f"Could not restore {self.original}: {restore_error}", file=sys.stderr)


@contextmanager
def popup_interrupts():
    """Wake the blocked selector when Rex closes the popup, even without keyboard input."""
    wake, notify = os.pipe()
    os.set_blocking(notify, False)
    previous_fd = signal.set_wakeup_fd(notify)
    signals = (signal.SIGHUP, signal.SIGTERM, signal.SIGINT)
    previous_handlers = {sig: signal.signal(sig, lambda *_: None) for sig in signals}
    try:
        yield wake
    finally:
        signal.set_wakeup_fd(previous_fd)
        for sig, handler in previous_handlers.items():
            signal.signal(sig, handler)
        os.close(wake)
        os.close(notify)


@contextmanager
def fzf_picker(presets, fifo):
    proc = subprocess.Popen(
        [
            "fzf", "--sync", "--layout=reverse", "--prompt=Theme › ",
            "--header=↑↓ preview · Enter to keep · Esc to restore",
            "--with-shell=/bin/sh -c",
            "--bind", "focus:execute-silent:printf '%s\\n' {} > \"$PICKER_FOCUS\"",
        ],
        stdin=subprocess.PIPE, stdout=subprocess.PIPE,
        env={**os.environ, "PICKER_FOCUS": str(fifo),
             "FZF_DEFAULT_OPTS": "", "FZF_DEFAULT_OPTS_FILE": ""},
    )
    try:
        with proc.stdin:
            proc.stdin.write(("\n".join(presets) + "\n").encode())
        yield proc
    finally:
        if proc.poll() is None:
            proc.terminate()
            try:
                proc.wait(timeout=0.5)
            except subprocess.TimeoutExpired:
                proc.kill()
                proc.wait()
        proc.stdout.close()


def read_choice(proc, focus, wake, presets, worker):
    with selectors.DefaultSelector() as events:
        for stream in (proc.stdout, focus, wake):
            events.register(stream, selectors.EVENT_READ)
        while True:
            ready = {key.fileobj for key, _ in events.select()}
            # A close or a final selection takes precedence over queued highlights.
            if wake in ready:
                return None
            if proc.stdout in ready:
                result = proc.stdout.read().decode().strip()
                code = proc.wait()
                if code == 0 and result in presets:
                    return result
                if code in (1, 130):
                    return None
                raise RuntimeError(f"fzf exited with status {code}")
            names = os.read(focus, 65536).decode().splitlines()
            if names and names[-1] in presets:
                worker.highlight(names[-1])


def pick(stage, presets, original):
    # The initial focus event should not repaint the already-active preset.
    ordered = [original, *(name for name in presets if name != original)]
    fifo = stage / "focus"
    os.mkfifo(fifo, 0o600)
    worker = Preview(stage, original)
    with popup_interrupts() as wake:
        focus = os.open(fifo, os.O_RDWR | os.O_NONBLOCK)
        choice = None
        worker.start()
        try:
            with fzf_picker(ordered, fifo) as proc:
                choice = read_choice(proc, focus, wake, presets, worker)
        finally:
            if choice is None:
                worker.cancel()
            else:
                worker.accept(choice)
            # Never let a late preview land after cancel has restored the theme.
            worker.join()
            os.close(focus)
    if worker.error:
        raise SystemExit(f"Theme picker failed: {worker.error}")


if __name__ == "__main__":
    os.environ["PATH"] = "/opt/homebrew/bin:/usr/local/bin:" + os.environ["PATH"]
    # Pickers in different Rex windows must not restore over one another.
    lock = os.open(CONFIG, os.O_RDONLY)
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        sys.exit("A shared theme picker is already open.")
    presets = sorted(d.name for d in (CONFIG / "themes").iterdir()
                     if re.fullmatch(r"[a-z0-9][a-z0-9-]*", d.name)
                     and (d / "opencode.json").is_file())
    link = CONFIG / "current-theme"
    original = link.resolve().name
    if not link.is_symlink() or original not in presets:
        sys.exit("Select an initial preset with ./dot theme <name> before opening the picker.")
    with tempfile.TemporaryDirectory(prefix=".theme-picker-", dir=CONFIG) as stage:
        pick(Path(stage), presets, original)
