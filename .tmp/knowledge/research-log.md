# Research Log

## 2026-05-02 - Flutter Barcode Scanner Packages

- **Source**: pub.dev (mobile_scanner, flutter_barcode_scanner), GitHub Issues
- **Files**: `.tmp/knowledge/barcode-scanner.md`
- **Key Insight**: `mobile_scanner` (v7.2.0, 781k weekly downloads) is the clear winner over legacy `flutter_barcode_scanner` (v2.0.0, 4.5k downloads). `quick_barcode_scanner` package doesn't exist on pub.dev.
- **Related systems**: Google ML Kit, Apple Vision Framework, ZXing

## 2026-05-02 - Flutter Local Notifications

- **Source**: pub.dev, GitHub, Official Documentation
- **Files**: `.tmp/knowledge/notifications.md`
- **Key insight**: `flutter_local_notifications` is the go-to package with 7.3k likes and 1.7M weekly downloads. For reliable background execution, combine with `workmanager`.
- **Related systems**: Android AlarmManager, WorkManager, Android notification channels

## 2026-11-19 14:30 - Android gallery opens Google Photos instead of system gallery

- **Source**: Plugin source (pub cache, image_picker_android 0.8.13+17), Official Android Docs (Photo Picker), pub.dev (photo_manager, wechat_assets_picker, gal)
- **Files**:
  - `.tmp/knowledge/image-picker/android-gallery-vs-google-photos.md`
- **Key Insights**:
  - `pickImage(source: gallery)` with default `useAndroidPhotoPicker = false` fires a bare `ACTION_GET_CONTENT` + `image/*` via `startActivityForResult`, **without** `Intent.createChooser` → Android default-handler resolution decides, so Google Photos opens if it is the (pre)selected handler. Not an app bug.
  - **Docs contradict code**: README (image_picker 1.2.2) and CHANGELOG 0.8.11 claim Android 13+ always uses the Photo Picker; `ImagePickerDelegate.java:463-478` proves `ACTION_GET_CONTENT` is fired unconditionally when the flag is false.
  - `useAndroidPhotoPicker` still exists in 0.8.13+17 and is still `false` by default.
  - The GMS Photo Picker backport `ModuleDependencies` service is already in the plugin's own AndroidManifest and merges into the app — no app-side manifest edit needed.
  - `maxWidth`/`imageQuality`/HEIC handling and `image_cropper` (uCrop) all keep working with the Photo Picker, because `FileUtils.getPathFromUri()` copies the `content://` URI to a real cache file *before* `ImageResizer` runs.
  - No `READ_MEDIA_IMAGES` needed for either `ACTION_GET_CONTENT` or the Photo Picker; those permissions are only needed for `photo_manager`/`wechat_assets_picker` (which also need Android 14 `READ_MEDIA_VISUAL_USER_SELECTED`).
  - `gal` and `photo_view` are **not** image pickers (gal = save-to-gallery; photo_view = zoomable widget) — common misconception, corrected.
  - Latent bug found (picker-independent): app never calls `ImagePicker.retrieveLostData()`, so a pick can be silently lost if Android kills MainActivity.
- **Top recommendation**: set `ImagePickerAndroid.useAndroidPhotoPicker = true` in `main()` before `runApp` — one flag, no new deps/permissions, deterministic system UI.
- **Related Systems**: image_picker, image_picker_android, Android Photo Picker, image_cropper (uCrop), photo_manager, wechat_assets_picker

## 2026-11-19 - Xiaomi MIUI/HyperOS gallery image-picking behaviour

- **Source**: Local pub cache source (file_picker 8.3.7 + 10.3.10, image_cropper 8.1.0), Xiaomi HyperOS developer platform, AOSP MediaProvider photopicker README, GitHub issues, Chinese dev write-ups, MIUI user forums
- **Files**:
  - `.tmp/knowledge/image-picker/miui-gallery-intent.md`
- **Key Insights**:
  - `file_picker` — **already a dependency of this app** — deliberately fires `ACTION_PICK` + `image/*` for `FileType.image` ("Use ACTION_PICK for images to allow using the Gallery app", verified in 10.3.10 source; same logic in resolved 8.3.7). It also copies the `content://` result to `cacheDir`, so `image_cropper` 8.1.0 (which requires `sourcePath: String`) works unchanged. This is the least invasive route to "open the Xiaomi Gallery".
  - Google Photos almost certainly does **not** register `ACTION_PICK`; its default-handler aggressiveness is on `ACTION_GET_CONTENT` / `ACTION_VIEW`. So switching action from `GET_CONTENT` to `PICK` is a targeted fix for the reported symptom.
  - `ACTION_PICK` has a real `ActivityNotFoundException` failure mode on devices with no preinstalled gallery (SO 66312517, PickImage#109) → a fallback to the Photo Picker is mandatory, not optional.
  - Xiaomi **officially recommends `MediaStore.ACTION_PICK_IMAGES`** for HyperOS 3 / Android 16+, jointly standardised via ITGSA (ColorOS 16, OriginOS 6, MagicOS 10). On older HyperOS/Android 13–15 that action is served by Google/AOSP MediaProvider — i.e. the picker the user dislikes is a transitional state, not a Xiaomi regression.
  - AOSP's PhotoPicker also answers plain `ACTION_GET_CONTENT` for images, so "GET_CONTENT → Google Photos" was never guaranteed on Android 13+; it only happens when Photos holds the default handler.
  - MIUI URI landmines: `ACTION_PICK` returns an encoded MediaStore URI (not a path), and some builds return `RESULT_OK` with a null `Intent`/data. Always `ContentResolver.openInputStream`, always null-check, never read `MediaStore.Images.Media.DATA`.
  - Hardcoding `setComponent` is not viable: the only publicly known component (`com.miui.gallery.activity.HomePageActivity`) is the **launcher** and never returns a pick result; the real picker activity is undocumented and version-specific; and it throws on every non-Xiaomi device.
  - `Intent.createChooser` around the pick intent is the worst option on this specific OEM: MIUI 12/Android 11 returns `RESULT_CANCELED` (CanHub/Android-Image-Cropper#253, pinned) and it costs a tap on every pick.
  - The exact `<intent-filter>` list of `com.miui.gallery` is **not** publicly verifiable → documented as uncertain, with `adb shell pm query-activities` / `dumpsys package com.miui.gallery` commands to settle it on the user's device.
- **Ranked recommendation**: (1) `ACTION_PICK` via `file_picker` with fallback to the Photo Picker; (2) keep the Photo Picker as-is (lowest risk, and it *is* the OEM-recommended API on HyperOS 3+); (3) `createChooser` (brand-neutral but worst MIUI bug history).
- **Related Systems**: image_picker, image_picker_android, image_cropper (uCrop), file_picker, com.miui.gallery, Android Photo Picker (ACTION_PICK_IMAGES), HyperOS/MIUI, ITGSA
