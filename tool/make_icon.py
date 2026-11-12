"""Builds all platform app icons from the approved Shopped brand artwork.

Run from the repo root: python tool/make_icon.py (requires Pillow and resvg-py).

Windows, Android, and in-app thumbs still use the transparent Daily Circle mark.
iOS and macOS App Store catalogs are the reviewed opaque cream-tile exports under
``assets/brand/app-store/`` (Apple applies the corner mask).
"""
from io import BytesIO
import shutil
from pathlib import Path
import xml.etree.ElementTree as ET

from PIL import Image
import resvg_py
from make_adaptive_icon import main as make_android_launcher_icons

SVG_SOURCE = Path("assets/brand/daily-circle-original-tangerine.svg")
SOURCE = Path("assets/brand/shopped-app-icon-original-tangerine.png")
APP_STORE = Path("assets/brand/app-store")
IOS_CATALOG = Path("ios/Runner/Assets.xcassets/AppIcon.appiconset")
MACOS_CATALOG = Path("macos/Runner/Assets.xcassets/AppIcon.appiconset")
ICNS_DESTINATION = Path("macos/Runner/ShoppedAppIcon.icns")
RESAMPLE = Image.Resampling.LANCZOS
MASTER_SIZE = 1024


def render_master(size=MASTER_SIZE):
    """Rasterize the approved SVG to a transparent square mark."""
    root = ET.parse(SVG_SOURCE).getroot()
    root.set("width", str(size))
    root.set("height", str(size))
    return Image.open(BytesIO(resvg_py.svg_to_bytes(
        svg_string=ET.tostring(root, encoding="unicode"),
    ))).convert("RGBA")


def resized(source, size):
    return source.resize((size, size), RESAMPLE)


def install_app_store_catalog(source_catalog: Path, destination: Path) -> None:
    """Replace a Flutter AppIcon.appiconset with the reviewed App Store export."""
    if not source_catalog.is_dir():
        raise FileNotFoundError(f"missing App Store catalog: {source_catalog}")
    if destination.exists():
        shutil.rmtree(destination)
    shutil.copytree(source_catalog, destination)


def main():
    source = render_master()
    SOURCE.parent.mkdir(parents=True, exist_ok=True)
    source.save(SOURCE, format="PNG", optimize=True)

    # Windows multi-resolution ICO; transparent pixels remain transparent.
    source.save(
        "windows/runner/resources/app_icon.ico",
        format="ICO",
        sizes=[(size, size) for size in (16, 24, 32, 48, 64, 128, 256)],
    )

    # Android adaptive, legacy, and round launcher icons (full-bleed circle).
    make_android_launcher_icons()

    # Reviewed opaque App Store catalogs for iOS and macOS.
    install_app_store_catalog(APP_STORE / "ios" / "AppIcon.appiconset", IOS_CATALOG)
    install_app_store_catalog(APP_STORE / "macos" / "AppIcon.appiconset", MACOS_CATALOG)
    shutil.copy2(APP_STORE / "macos" / "ShoppedAppIcon.icns", ICNS_DESTINATION)

    # In-app preview and Windows title-bar / taskbar image.
    resized(source, 96).save("assets/app_icon.png", format="PNG", optimize=True)
    resized(source, 512).save("tool/icon_preview.png", format="PNG", optimize=True)
    # Keep the About mark aligned with the same transparent master.
    resized(source, 256).save("assets/brand/shopped-mark.png", format="PNG", optimize=True)


if __name__ == "__main__":
    main()
