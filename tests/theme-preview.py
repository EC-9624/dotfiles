"""Exercise rapid picker input while a previous live update is still running."""
import runpy
import threading
import unittest
from pathlib import Path

Preview = runpy.run_path(str(Path(__file__).resolve().parents[1] / "home/.config/rex/theme-picker.py"))["Preview"]


class SlowPreview(Preview):
    def __init__(self):
        super().__init__(None, "gruvbox")
        self.started = threading.Event()
        self.release = threading.Event()
        self.calls = []

    def apply(self, operation, name):
        self.calls.append((operation, name))
        if (operation, name) == ("preview", "rose-pine"):
            self.started.set()
            if not self.release.wait(3):
                raise TimeoutError("preview wasn't released")


class PreviewTest(unittest.TestCase):
    def finish_during_preview(self, finish):
        worker = SlowPreview()
        worker.start()
        try:
            worker.highlight("rose-pine")
            self.assertTrue(worker.started.wait(3))
            worker.highlight("tokyo-night")
            finish(worker)
        finally:
            worker.release.set()
        worker.join(3)
        self.assertFalse(worker.is_alive())
        self.assertIsNone(worker.error)
        return worker.calls

    def test_cancel_discards_pending_preview_then_restores(self):
        self.assertEqual(self.finish_during_preview(Preview.cancel), [
            ("prepare", "gruvbox"), ("preview", "rose-pine"), ("preview", "gruvbox"),
        ])

    def test_enter_during_preview_only_commits_final_choice(self):
        self.assertEqual(self.finish_during_preview(lambda worker: worker.accept("catppuccin")), [
            ("prepare", "gruvbox"), ("preview", "rose-pine"),
            ("preview", "catppuccin"), ("commit", "catppuccin"),
        ])

    def test_accept_original_without_navigation_does_not_repaint(self):
        worker = SlowPreview()
        worker.start()
        worker.accept("gruvbox")
        worker.join(3)
        self.assertFalse(worker.is_alive())
        self.assertEqual(worker.calls, [("prepare", "gruvbox")])


if __name__ == "__main__":
    unittest.main()
