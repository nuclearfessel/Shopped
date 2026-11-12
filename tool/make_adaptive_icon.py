"""Install reviewed Android launcher icons from the approved brand handoff.

Run from the repository root: python tool/make_adaptive_icon.py

Legacy mipmaps are opaque cream-plate RGB squares. Adaptive icons use the cream
``ic_launcher_background`` color plus transparent foreground/monochrome layers.
"""
from pathlib import Path
import shutil

BRAND_RES = Path("assets/brand/android/res")
RES = Path("android/app/src/main/res")
DENSITIES = ("mdpi", "hdpi", "xhdpi", "xxhdpi", "xxxhdpi")
OLD_DENSITY_DRAWABLES = (
    "drawable-mdpi",
    "drawable-hdpi",
    "drawable-xhdpi",
    "drawable-xxhdpi",
    "drawable-xxxhdpi",
)


def _replace_tree(src: Path, dest: Path) -> None:
    if not src.is_dir():
        raise FileNotFoundError(src)
    if dest.exists():
        shutil.rmtree(dest)
    shutil.copytree(src, dest)


def _replace_file(src: Path, dest: Path) -> None:
    if not src.is_file():
        raise FileNotFoundError(src)
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dest)


def install_android_launcher_icons() -> None:
    """Copy the reviewed Android ``res`` tree into the Flutter Android module."""
    if not BRAND_RES.is_dir():
        raise FileNotFoundError(f"missing Android brand resources: {BRAND_RES}")

    _replace_tree(BRAND_RES / "mipmap-anydpi-v26", RES / "mipmap-anydpi-v26")
    _replace_tree(BRAND_RES / "drawable-nodpi", RES / "drawable-nodpi")
    _replace_file(
        BRAND_RES / "values" / "ic_launcher_background.xml",
        RES / "values" / "ic_launcher_background.xml",
    )
    for density in DENSITIES:
        _replace_tree(BRAND_RES / f"mipmap-{density}", RES / f"mipmap-{density}")

    # Previous adaptive layers lived in density-specific drawables; remove leftovers.
    for density_dir in OLD_DENSITY_DRAWABLES:
        folder = RES / density_dir
        if not folder.is_dir():
            continue
        for name in ("ic_launcher_foreground.png", "ic_launcher_background.png"):
            (folder / name).unlink(missing_ok=True)
        if not any(folder.iterdir()):
            folder.rmdir()


def main():
    install_android_launcher_icons()


if __name__ == "__main__":
    main()
