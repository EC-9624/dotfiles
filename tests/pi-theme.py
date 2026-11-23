"""Exercise Pi theme switching through the shared Rex picker helper."""
import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
HELPER = ROOT / "home/.config/rex/apply-picker-theme.sh"


class PiThemeTest(unittest.TestCase):
    def setUp(self):
        scratch = tempfile.TemporaryDirectory()
        self.addCleanup(scratch.cleanup)
        home = Path(scratch.name)
        config = home / ".config"
        config.mkdir()
        (config / "themes").symlink_to(ROOT / "home/.config/themes", target_is_directory=True)
        (config / "current-theme").symlink_to(config / "themes/catppuccin", target_is_directory=True)
        self.stage = config / "stage"
        self.stage.mkdir()
        (self.stage / "clients").touch()  # Do not call live Rex clients.
        opencode = config / "opencode"
        opencode.mkdir()
        (opencode / "cli.json").write_text('{"theme":{"name":"dotfiles-catppuccin"}}\n')
        agent = home / "pi-config"
        self.palette = agent / "themes/dotfiles-shared.json"
        self.env = {**os.environ, "HOME": str(home), "XDG_CONFIG_HOME": str(config),
                    "PI_CODING_AGENT_DIR": str(agent)}

    def preview(self, name):
        subprocess.run(["/bin/bash", HELPER, "preview", self.stage, name],
                       env=self.env, check=True)
        palette = json.loads(self.palette.read_text())
        colors = palette["colors"]
        self.assertEqual(colors["toolPendingBg"], colors["userMessageBg"])
        self.assertEqual(colors["toolSuccessBg"], colors["toolPendingBg"])
        self.assertEqual(colors["toolErrorBg"], colors["toolPendingBg"])
        self.assertNotEqual(colors["customMessageBg"], colors["toolPendingBg"])
        return palette

    def test_picker_preview_and_restore_use_one_watched_filename(self):
        original = self.preview("catppuccin")
        self.assertEqual(original["name"], "dotfiles-shared")
        for name in ("gruvbox", "opencode", "rose-pine", "tokyo-night"):
            with self.subTest(name=name):
                preview = self.preview(name)
                self.assertEqual(preview["name"], original["name"])
                self.assertNotEqual(preview["colors"]["accent"], original["colors"]["accent"])
        self.assertEqual(self.preview("catppuccin"), original)
        self.assertEqual(list(self.palette.parent.iterdir()), [self.palette])


if __name__ == "__main__":
    unittest.main()
