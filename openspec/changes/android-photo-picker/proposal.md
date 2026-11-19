# Proposal

## Why

On Android, tapping "Галерея" in the product form opens Google Photos rather
than the device gallery. The `image_picker` plugin fires an implicit
`ACTION_GET_CONTENT` intent for `image/*` without `createChooser`, so Android
resolves it to the default handler — and Google Photos declares that intent.
On devices with no separate gallery app (e.g. Pixel), the user is effectively
locked into Google Photos for every product photo.

## What Changes

- Enable the Android system Photo Picker (`ImagePickerAndroid.useAndroidPhotoPicker = true`)
  so gallery selection uses the OS-owned picker UI instead of an external app.
- Declare `image_picker_android` and `image_picker_platform_interface` as direct
  dependencies (they are currently transitive-only) to satisfy
  `depend_on_referenced_packages`.
- Recover photos lost to Android process death while the picker is foregrounded
  by handling `ImagePicker.retrieveLostData()`.

## Capabilities

### New Capabilities

- `product-image-picking`: How the app lets a user attach a photo to a product —
  which system surface is used for camera/gallery selection, what happens to the
  selection afterwards, and how an interrupted selection is recovered.

### Modified Capabilities

<!-- None: no existing capability's requirements change. -->

## Impact

- `lib/main.dart` — one-time Android Photo Picker opt-in during startup.
- `lib/widgets/product_form.dart` — lost-data recovery on resume.
- `pubspec.yaml` — two new direct dependencies (already present transitively,
  no version change).
- No manifest permissions added; the system Photo Picker requires none.
- `image_cropper` (uCrop) flow unchanged: the plugin still materialises a real
  cache file path before returning.
- Android only. iOS/web/desktop behaviour is unaffected.
