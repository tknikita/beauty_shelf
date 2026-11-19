# Design

## Context

`lib/widgets/product_form.dart` owns image selection: a source dialog returns
`ImageSource.camera` or `ImageSource.gallery` and the result is passed through
`ImageCropper` (uCrop) before being persisted via
`StorageService.saveImageBytes`. The form is a plain `StatefulWidget`;
`_imageUrl` holds the attached image and `_isUploadingImage` gates the progress
indicator.

`image_picker_android` 0.8.13+17 branches on `useAndroidPhotoPicker` (default
`false`); with the default it starts `ACTION_GET_CONTENT` for `image/*` without
`createChooser`, which resolves to whatever app owns the default handler —
Google Photos on most devices. With the flag on it starts
`MediaStore.ACTION_PICK_IMAGES`, the system Photo Picker, which OEM galleries
do not participate in. Neither path opens the vendor gallery.
`ImagePicker` is a fresh instance per upload and nothing calls
`retrieveLostData()`.

`MainActivity.kt` is currently an empty `FlutterActivity` subclass with no
platform channels.

See proposal.md for motivation.

## Goals / Non-Goals

**Goals:**

- Open the device's own gallery app for image selection on Android, without
  ever routing to Google Photos while a real gallery exists.
- Keep the existing crop → persist → attach pipeline unchanged.
- Recover a selection lost to process death without duplicating the
  post-pick logic.

**Non-Goals:**

- Building an in-app gallery grid (no `photo_manager` / `wechat_assets_picker`).
- Persisting the rest of the half-filled product form across process death.
- Changing camera behaviour, or any non-Android platform.

## Decisions

### Resolve the gallery handler on the native side and target it explicitly

`MediaStore.ACTION_PICK_IMAGES` (the system Photo Picker) is a Google component
that OEM galleries take no part in — on MIUI it replaces the Gallery app the
user expects. `Intent.ACTION_PICK` is the classic gallery intent, but Google
Photos registers it too, and its external picker only shows that app's own
library (observed empty on a stock emulator).

`MainActivity` therefore exposes a `MethodChannel`
(`com.beautyshelf.beauty_shelf/gallery`, method `pickImage`) that:

1. Builds `ACTION_PICK` + `type=image/*`.
2. Calls `queryIntentActivities` and takes the **first handler that is not
   `com.google.android.apps.photos`**.
3. If such a handler exists, launches the intent with `setPackage(...)`, which
   makes the choice deterministic instead of leaving it to default-handler
   resolution.
4. Otherwise falls back to `ACTION_PICK_IMAGES` (API 33+) or
   `ACTION_OPEN_DOCUMENT` — never to Photos.
5. On result, copies the `content://` payload into `cacheDir/gallery_pick/` and
   returns a real path, because uCrop needs a file and the URI grant is
   one-shot.

The chosen action and package are logged under the `BeautyShelfGallery` tag so
device-specific behaviour is diagnosable from logcat.

*Alternatives considered:* `file_picker` (already a dependency) fires
`ACTION_PICK` for `FileType.image`, but offers no handler preference and no
`setPackage`, so it cannot keep Google Photos out. A Flutter `photo_manager`
grid was rejected as a much larger change that would abandon the native gallery
entirely.

### Keep `useAndroidPhotoPicker` as the Dart-side fallback

The Dart fallback path still uses `ImagePicker` with
`useAndroidPhotoPicker = true` (set in `main()`), so a missing or failing native
bridge degrades to the system Photo Picker rather than to Google Photos.

### Declare the two transitive packages as direct dependencies

`image_picker_android` and `image_picker_platform_interface` are currently
transitive. Importing them directly trips `depend_on_referenced_packages`, so
both are added to `pubspec.yaml` at the versions already resolved
(`0.8.13+17` and `2.11.1`).

### Declare `ACTION_PICK` in `<queries>`

Android 11+ package visibility hides gallery apps from `queryIntentActivities`
unless the app declares the intent it is resolving. The manifest adds an
`ACTION_PICK` / `image/*` `<queries>` entry; without it the handler list comes
back empty and every device would fall through to the photo picker.

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

- **Not every OEM gallery registers `ACTION_PICK`** → the handler query is the
  source of truth; devices with no matching gallery fall back to the photo
  picker, which is a visible downgrade but never a dead end. The chosen
  package is logged for diagnosis.
- **Picker UI now varies by device** (MIUI, One UI, AOSP) → accepted: that is
  the point — the user asked for their own gallery.
- **Another non-gallery app could register `ACTION_PICK`** and win the query →
  mitigated by excluding Google Photos explicitly; other false positives would
  still present an image-picking UI, so the outcome stays usable.
- **`useAndroidPhotoPicker` is marked "subject to change"** → pinned by the
  direct dependency on `image_picker_android 0.8.13+17`; it only affects the
  fallback path now.
- **Recovered photo has no form around it** after process death → the stash is
  in-memory only and is consumed by the next form the user opens with no image
  yet; the rest of the form is still lost, which is explicitly a non-goal.
- **Double recovery** if `check()` runs twice → `take()` nulls the field, and
  `retrieveLostData()` does not redeliver the same payload, so the flow fires
  at most once per lost selection.
- **`maxWidth` is no longer applied before the crop on the gallery path**
  (the native side copies the original) → uCrop caps the output at 1600 px
  instead, which keeps the stored image the same size as before.
