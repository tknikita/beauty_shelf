# Design

## Context

`lib/widgets/product_form.dart` owns image selection: a source dialog returns
`ImageSource.camera` or `ImageSource.gallery`, `ImagePicker.pickImage(...)` is
called, and the result is passed through `ImageCropper` (uCrop) before being
persisted via `StorageService.saveImageBytes`. The form is a plain
`StatefulWidget`; `_imageUrl` holds the attached image and `_isUploadingImage`
gates the progress indicator.

`image_picker_android` 0.8.13+17 branches on `useAndroidPhotoPicker` (default
`false`); with the default it starts `ACTION_GET_CONTENT` for `image/*` without
`createChooser`, which resolves to whatever app owns the default handler.
`ImagePicker` is a fresh instance per upload and nothing calls
`retrieveLostData()`.

See proposal.md for motivation.

## Goals / Non-Goals

**Goals:**

- Route gallery selection through the OS-owned picker on Android with a
  one-time, app-wide opt-in.
- Reuse the existing crop → persist → attach pipeline unchanged.
- Recover a selection lost to process death without duplicating the
  post-pick logic.

**Non-Goals:**

- Building an in-app gallery grid (no `photo_manager` / `wechat_assets_picker`).
- Persisting the rest of the half-filled product form across process death.
- Changing camera behaviour, or any non-Android platform.

## Decisions

### Enable the system Photo Picker once, in `main()`

```dart
final impl = ImagePickerPlatform.instance;
if (impl is ImagePickerAndroid) impl.useAndroidPhotoPicker = true;
```

Placed right after `WidgetsFlutterBinding.ensureInitialized()` and before
`runApp`, alongside the existing startup work.

`useAndroidPhotoPicker` is an instance field on the registered platform
implementation, so it must be set on `ImagePickerPlatform.instance`, not on a
local `ImagePicker`. Setting it in `main()` means every later `ImagePicker()`
call inherits it, including the one-off instance used for lost-data recovery.

*Alternatives considered:* `android_intent_plus` cannot launch an intent
`forResult`, so it would need a real `MethodChannel`; `ACTION_PICK` is just as
resolver-dependent as `ACTION_GET_CONTENT`. Both rejected as more code for a
worse result.

### Declare the two transitive packages as direct dependencies

`image_picker_android` and `image_picker_platform_interface` are currently
transitive. Importing them directly trips `depend_on_referenced_packages`, so
both are added to `pubspec.yaml` at the versions already resolved
(`0.8.13+17` and `2.11.1`). No lockfile movement is expected beyond marking
them `direct main`.

### Recovery lives in a small app-level stash, consumed by the form

`retrieveLostData()` must be checked on the widget that survives the
interruption. On process death the app restarts at the home screen, so
`ProductForm` does not exist yet — checking only inside the form would never
recover anything.

A tiny `ImageRecovery` singleton (`lib/services/image_recovery.dart`) wraps the
check:

- `check()` → calls `ImagePicker().retrieveLostData()`, keeps the first
  recovered `XFile` in a nullable field, and clears any plugin-side state by
  virtue of the call itself.
- `take()` → returns the stashed file once and nulls the field, making recovery
  idempotent.

`_BeautyShelfAppState` implements `WidgetsBindingObserver`, calls `check()` in
`initState` and on `AppLifecycleState.resumed`, which covers both cold start
and activity re-creation. `ProductForm.initState` calls `take()` and, if it
gets a file while `_imageUrl` is still null, schedules the crop-and-attach flow
in a post-frame callback (dialogs need a mounted context).

*Alternatives considered:* calling `retrieveLostData()` inside
`ProductForm.initState` only — simplest, but blind to the cold-start case where
the form is gone. Rejected because it would make the requirement unfulfillable.

### Extract the post-pick pipeline into a reusable method

`_uploadImage` currently mixes source selection, picking, and attachment.
Picking moves out; the new `_applyPickedImage(XFile)` holds crop → persist →
snackbar → `_isUploadingImage` toggling. Both the normal path and recovery use
it, so the two cannot drift.

### No manifest or permission changes

The system Photo Picker needs no media permission; `READ_MEDIA_IMAGES` /
`READ_EXTERNAL_STORAGE` remain absent. Camera permission is untouched.

## Risks / Trade-offs

- **Photo Picker UI differs from the Google Photos app** (system grid, its own
  "Add from cloud" affordance) → accepted: this is the requested change; the
  user can still reach cloud photos from within the picker.
- **`useAndroidPhotoPicker` is marked "subject to change"** and the plugin's
  README claims Android 13+ already uses the photo picker while the shipped
  source proves otherwise → pinned by the direct dependency on
  `image_picker_android 0.8.13+17`; revisit on plugin upgrade.
- **Recovered photo has no form around it** after process death → the stash is
  in-memory only and is consumed by the next form the user opens with no image
  yet; the rest of the form is still lost, which is explicitly a non-goal.
- **Double recovery** if `check()` runs twice → `take()` nulls the field, and
  `retrieveLostData()` does not redeliver the same payload, so the flow fires
  at most once per lost selection.
- **`maxWidth` / `imageQuality` silently ignored?** → verified not the case:
  the plugin materialises a real cache file from the `content://` URI before
  resizing, so both the resize and the uCrop step keep working.
