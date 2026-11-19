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
