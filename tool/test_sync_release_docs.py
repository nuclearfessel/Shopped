"""Tests for README / product-page release version sync."""
import tempfile
import unittest
from pathlib import Path

from sync_release_docs import sync_release_doc_text, sync_root, version_from_pubspec


README_FIXTURE = """## Download

**Current version: 1.0.1**

| Platform | Package |
| --- | --- |
| Windows | [Shopped-Setup-1.0.1.exe](https://github.com/nuclearfessel/Shopped/releases/download/v1.0.1/Shopped-Setup-1.0.1.exe) |
| Android | [Shopped-1.0.1.apk](https://github.com/nuclearfessel/Shopped/releases/download/v1.0.1/Shopped-1.0.1.apk) |
| Mac | [Shopped-1.0.1-macos.zip](https://github.com/nuclearfessel/Shopped/releases/download/v1.0.1/Shopped-1.0.1-macos.zip) |

Each release bumps the patch (`1.0.0` → `1.0.1` … `1.0.9` → `1.1.0`, and so on through `9.9.9` → `10.0.0`).
"""

INDEX_FIXTURE = """<a class="button button-primary" href="#download">Get Shopped 1.0.1</a>
<p>Current version 1.0.1. Installers replace an older build.</p>
<a href="https://github.com/nuclearfessel/Shopped/releases/download/v1.0.1/Shopped-Setup-1.0.1.exe">
  <span>Shopped-Setup-1.0.1.exe</span>
</a>
<a href="https://github.com/nuclearfessel/Shopped/releases/download/v1.0.1/Shopped-1.0.1.apk">
  <span>Shopped-1.0.1.apk</span>
</a>
<a href="https://github.com/nuclearfessel/Shopped/releases/download/v1.0.1/Shopped-1.0.1-macos.zip">
  <span>Shopped-1.0.1-macos.zip</span>
</a>
"""


class SyncReleaseDocTextTests(unittest.TestCase):
    def test_readme_download_block(self):
        updated = sync_release_doc_text(README_FIXTURE, "1.1.2")
        self.assertIn("**Current version: 1.1.2**", updated)
        self.assertIn("Shopped-Setup-1.1.2.exe", updated)
        self.assertIn("/download/v1.1.2/", updated)
        self.assertIn("Shopped-1.1.2.apk", updated)
        self.assertIn("Shopped-1.1.2-macos.zip", updated)
        # Prose examples must stay put.
        self.assertIn("`1.0.0` → `1.0.1`", updated)
        self.assertIn("`1.0.9` → `1.1.0`", updated)

    def test_index_download_block(self):
        updated = sync_release_doc_text(INDEX_FIXTURE, "1.1.2")
        self.assertIn("Get Shopped 1.1.2", updated)
        self.assertIn("Current version 1.1.2.", updated)
        self.assertIn("/download/v1.1.2/Shopped-Setup-1.1.2.exe", updated)
        self.assertNotIn("1.0.1", updated)

    def test_rejects_bad_version(self):
        with self.assertRaises(ValueError):
            sync_release_doc_text(README_FIXTURE, "v1.1.2")


class SyncRootTests(unittest.TestCase):
    def test_writes_changed_files(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "docs").mkdir()
            readme = root / "README.md"
            index = root / "docs" / "index.html"
            readme.write_text(README_FIXTURE, encoding="utf-8")
            index.write_text(INDEX_FIXTURE, encoding="utf-8")
            changed = sync_root(root, "1.1.2")
            self.assertEqual(changed, [Path("README.md"), Path("docs/index.html")])
            self.assertIn("1.1.2", readme.read_text(encoding="utf-8"))
            self.assertIn("1.1.2", index.read_text(encoding="utf-8"))
            self.assertEqual(sync_root(root, "1.1.2"), [])

    def test_pubspec_version(self):
        self.assertEqual(version_from_pubspec("version: 1.1.2+45\n"), "1.1.2")


if __name__ == "__main__":
    unittest.main()
