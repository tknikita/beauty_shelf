# Tasks

## 1. Dependencies

- [x] 1.1 Add `image_picker_android` (0.8.13+17) and `image_picker_platform_interface` (2.11.1) to `pubspec.yaml` dependencies and verify `flutter pub get` resolves without changing other locked versions

## 2. Gallery routing

- [x] 2.1 Set `useAndroidPhotoPicker = true` on `ImagePickerPlatform.instance` when it is an `ImagePickerAndroid`, in `main()` before `runApp`, so the Dart fallback degrades to the photo picker and not to Google Photos
- [x] 2.2 Add a `com.beautyshelf.beauty_shelf/gallery` method channel in `MainActivity.kt` that resolves `ACTION_PICK`, prefers any handler other than Google Photos, targets it with `setPackage`, and falls back to `ACTION_PICK_IMAGES` / `ACTION_OPEN_DOCUMENT`
- [x] 2.3 Copy the returned `content://` payload into `cacheDir/gallery_pick/` and return a real path for uCrop
- [x] 2.4 Declare `ACTION_PICK` / `image/*` in the manifest `<queries>` so gallery apps are visible to `queryIntentActivities` on Android 11+
- [x] 2.5 Verify on the emulator that with a gallery app installed the picker launches that app explicitly (`action=android.intent.action.PICK pkg=<gallery>`), and that removing it falls back to the system photo picker
- [x] 2.6 Verify on a real HyperOS device that the Xiaomi file manager (which also answers `ACTION_PICK`) is skipped in favour of `com.miui.gallery`, confirmed from the `BeautyShelfGallery` log, and that the picked image reaches uCrop

## 3. Lost-selection recovery

- [x] 3.1 Add `lib/services/image_recovery.dart` with `ImageRecovery` (`check()` / `take()` over `retrieveLostData()`) and verify it compiles with no analyzer warnings
- [x] 3.2 Wire `WidgetsBindingObserver` into `_BeautyShelfAppState`: call `ImageRecovery.check()` in `initState` and on `AppLifecycleState.resumed`, and verify the observer is removed in `dispose()`
- [x] 3.3 Extract the post-pick pipeline from `_uploadImage` into `_applyPickedImage(XFile)` and verify camera and gallery attach paths still behave identically
- [x] 3.4 Consume `ImageRecovery.take()` in `ProductForm.initState` via a post-frame callback when no image is attached yet, and verify a recovered file runs the crop-and-attach flow exactly once

## 4. Verification

- [x] 4.1 Run `flutter analyze` with zero new issues
- [x] 4.2 Run `flutter test` and confirm the suite passes
- [x] 4.3 Manually verify: pick → crop → attach shows the image and the "Изображение добавлено" snackbar; dismissing the crop leaves the old image and stores no file
- [x] 4.4 Manually verify on Android that no media-library permission prompt appears during picking

## 5. Release

- [x] 5.1 Build the Android release artifact and confirm it is produced at the expected output path
