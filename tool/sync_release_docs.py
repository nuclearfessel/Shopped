"""Keep README and product-page download versions aligned with a release.

Targets the Shopped download sections in README.md and docs/index.html.
Does not rewrite the versioning examples in README prose
(for example ``1.0.0`` → ``1.0.1``).

Run from the repo root:
  python tool/sync_release_docs.py --version 1.1.2
  python tool/sync_release_docs.py              # use pubspec.yaml version
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

VERSION_NAME_RE = re.compile(r"^version:\s*(\d+\.\d+\.\d+)(?:\+\d+)?\s*$", re.MULTILINE)
DOC_PATHS = (
    Path("README.md"),
    Path("docs/index.html"),
)


def version_from_pubspec(text: str) -> str:
    match = VERSION_NAME_RE.search(text)
    if match is None:
        raise ValueError("pubspec.yaml has no version: major.minor.patch line")
    return match.group(1)


def sync_release_doc_text(text: str, version: str) -> str:
    """Rewrite download/current-version mentions to ``version``."""
    if not re.fullmatch(r"\d+\.\d+\.\d+", version):
        raise ValueError(f"version must be major.minor.patch, got {version!r}")

    updated = text
    updated = re.sub(
        r"(\*\*Current version:\s*)\d+\.\d+\.\d+(\*\*)",
        rf"\g<1>{version}\2",
        updated,
    )
    updated = re.sub(
        r"(Current version\s+)\d+\.\d+\.\d+",
        rf"\g<1>{version}",
        updated,
    )
    updated = re.sub(
        r"(Get Shopped\s+)\d+\.\d+\.\d+",
        rf"\g<1>{version}",
        updated,
    )
    updated = re.sub(
        r"(releases/download/)v\d+\.\d+\.\d+/",
        rf"\g<1>v{version}/",
        updated,
    )
    updated = re.sub(
        r"(Shopped-Setup-)\d+\.\d+\.\d+(\.exe)",
        rf"\g<1>{version}\2",
        updated,
    )
    updated = re.sub(
        r"(Shopped-)\d+\.\d+\.\d+(\.apk)",
        rf"\g<1>{version}\2",
        updated,
    )
    updated = re.sub(
        r"(Shopped-)\d+\.\d+\.\d+(-macos\.zip)",
        rf"\g<1>{version}\2",
        updated,
    )
    updated = re.sub(
        r"(Shopped-)\d+\.\d+\.\d+(-ios-install\.zip)",
        rf"\g<1>{version}\2",
        updated,
    )
    updated = re.sub(
        r"(Shopped-)\d+\.\d+\.\d+(\.ipa)",
        rf"\g<1>{version}\2",
        updated,
    )
    return updated


def sync_root(root: Path, version: str) -> list[Path]:
    changed: list[Path] = []
    for relative in DOC_PATHS:
        path = root / relative
        original = path.read_text(encoding="utf-8")
        updated = sync_release_doc_text(original, version)
        if updated == original:
            continue
        path.write_text(updated, encoding="utf-8", newline="\n")
        changed.append(relative)
    return changed


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--root",
        type=Path,
        default=Path(__file__).resolve().parents[1],
        help="repository root",
    )
    parser.add_argument(
        "--version",
        help="release version (major.minor.patch). Defaults to pubspec.yaml.",
    )
    args = parser.parse_args(argv)
    root = args.root
    version = args.version
    if version is None:
        version = version_from_pubspec((root / "pubspec.yaml").read_text(encoding="utf-8"))
    changed = sync_root(root, version)
    if not changed:
        print(f"Release docs already at {version}")
    else:
        for path in changed:
            print(f"Updated {path.as_posix()} → {version}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as error:  # noqa: BLE001 - CLI boundary
        print(f"sync_release_docs: {error}", file=sys.stderr)
        raise SystemExit(1) from error
