# Android icon setup

This folder is included for **Shopped only**.

- `Android/res/` contains launcher density assets, adaptive icon resources,
  monochrome support, and the XML/color resources they reference.
- `Android/adaptive-icon/` contains transparent foreground/background sources.
- `Android/google-play/shopped-play-store-512.png` is the full-square,
  512 × 512 opaque Google Play listing image.

Copy the complete `Android/res/` tree into the Android app module's
`app/src/main/res/`. In the app manifest, set
`android:icon="@mipmap/ic_launcher"` and
`android:roundIcon="@mipmap/ic_launcher_round"`. Keep the API 26+ adaptive
XML and its referenced resources together. Upload only the 512 × 512 PNG to
the Play Store listing; Google applies its own shape and shadow.

Android Studio/Gradle builds and store ingestion were not run; no app source
or store listing was changed.

References:
- https://developer.android.com/develop/ui/compose/system/icon_design_adaptive
- https://developer.android.com/google-play/resources/icon-design-specifications
