# Tasks

## 1. Dependencies

- [x] 1.1 Add `image_picker_android` (0.8.13+17) and `image_picker_platform_interface` (2.11.1) to `pubspec.yaml` dependencies and verify `flutter pub get` resolves without changing other locked versions

## 2. Enable the system Photo Picker

- [x] 2.1 Set `useAndroidPhotoPicker = true` on `ImagePickerPlatform.instance` when it is an `ImagePickerAndroid`, in `main()` before `runApp`, and verify the app builds (`flutter analyze`)
- [ ] 2.2 Verify on an Android device/emulator that tapping "Галерея" opens the system photo picker and not Google Photos

## 3. Lost-selection recovery

- [x] 3.1 Add `lib/services/image_recovery.dart` with `ImageRecovery` (`check()` / `take()` over `retrieveLostData()`) and verify it compiles with no analyzer warnings
- [x] 3.2 Wire `WidgetsBindingObserver` into `_BeautyShelfAppState`: call `ImageRecovery.check()` in `initState` and on `AppLifecycleState.resumed`, and verify the observer is removed in `dispose()`
- [x] 3.3 Extract the post-pick pipeline from `_uploadImage` into `_applyPickedImage(XFile)` and verify camera and gallery attach paths still behave identically
- [x] 3.4 Consume `ImageRecovery.take()` in `ProductForm.initState` via a post-frame callback when no image is attached yet, and verify a recovered file runs the crop-and-attach flow exactly once

## 4. Verification

- [x] 4.1 Run `flutter analyze` with zero new issues
- [x] 4.2 Run `flutter test` and confirm the suite passes
- [ ] 4.3 Manually verify: pick → crop → attach shows the image and the "Изображение добавлено" snackbar; dismissing the crop leaves the old image and stores no file
- [x] 4.4 Manually verify on Android that no media-library permission prompt appears during picking

## 5. Release

- [x] 5.1 Build the Android release artifact and confirm it is produced at the expected output path
