---
source: Plugin source (pub cache) + Official Docs + pub.dev
topic: Android gallery opens Google Photos instead of system gallery
systems: image_picker, image_picker_android, Android Photo Picker, image_cropper, photo_manager, wechat_assets_picker
created: 2026-11-19
last-verified: 2026-11-19
researcher: ResearchAgent
project: beauty_shelf
tags: [flutter, android, image-picker, photo-picker, google-photos, ucrop, permissions]
---

# Research: `ImageSource.gallery` opens Google Photos instead of the built-in Gallery

## Context (as observed in this repo)

| Item | Value |
|---|---|
| App package | `polochka` |
| `image_picker` | `^1.0.0` → resolved **1.2.2** |
| `image_picker_android` | **0.8.13+17** |
| Dart SDK | `^3.11.5` |
| Call site | `lib/widgets/product_form.dart:191` |
| Call | `ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 90)` |
| Post-processing | `ImageCropper().cropImage(...)` (uCrop on Android), `lib/widgets/product_form.dart:241` |
| Manifest | `CAMERA`, `INTERNET`, `POST_NOTIFICATIONS`, `VIBRATE`, `RECEIVE_BOOT_COMPLETED` — **no** `READ_MEDIA_IMAGES` / `READ_EXTERNAL_STORAGE` |

## Summary

The plugin fires a bare **implicit `ACTION_GET_CONTENT` (`image/*`)** intent. Android then resolves it via normal intent resolution — and if Google Photos is the (pre)selected default handler, it opens directly, with no chooser. This is OS-level handler resolution, **not an app bug**, and the app cannot dictate *which* gallery app handles it. The reliable fix is to opt into the **system Photo Picker** (`ImagePickerAndroid.useAndroidPhotoPicker = true`), which is not an intent at all — it is a system-owned UI that is identical on every device.

---

## Q1 — Exactly what intent does `image_picker_android` 0.8.13+17 fire for `ImageSource.gallery`?

**Answer: `ACTION_GET_CONTENT` with type `image/*`. Not `ACTION_PICK`, not `ACTION_PICK_IMAGES`.**

Verified in the installed plugin source (authoritative for 0.8.13+17):

`~/.pub-cache/hosted/pub.dev/image_picker_android-0.8.13+17/android/src/main/java/io/flutter/plugins/imagepicker/ImagePickerDelegate.java:463-478`

```java
private void launchPickImageFromGalleryIntent(Boolean usePhotoPicker) {
    Intent pickImageIntent;
    if (usePhotoPicker) {
      pickImageIntent =
          new ActivityResultContracts.PickVisualMedia()
              .createIntent(
                  activity,
                  new PickVisualMediaRequest.Builder()
                      .setMediaType(ActivityResultContracts.PickVisualMedia.ImageOnly.INSTANCE)
                      .build());
    } else {
      pickImageIntent = new Intent(Intent.ACTION_GET_CONTENT);
      pickImageIntent.setType("image/*");
    }
    activity.startActivityForResult(pickImageIntent, REQUEST_CODE_CHOOSE_IMAGE_FROM_GALLERY);
}
```

Key points:

- `usePhotoPicker` is `false` by default → **`ACTION_GET_CONTENT` + `setType("image/*")`**, started with `startActivityForResult` (no `Intent.createChooser()` wrapper).
- Multi-image (`launchMultiPickImageFromGalleryIntent`, line 480) is the same intent plus `EXTRA_ALLOW_MULTIPLE`.
- `chooseMediaFromGallery` (line 305) is a *different* path: `ACTION_GET_CONTENT` with `setType("*/*")` + `CONTENT_TYPE` extra. **`pickImage()` does not use it.**
- The camera path is unrelated (`MediaStore.ACTION_IMAGE_CAPTURE`).

### ⚠️ Documentation contradiction (important)

The package README and changelog claim the photo picker is used automatically on Android 13+:

- `image_picker-1.2.2/README.md:89-93` — *"On Android 13 and above this package uses the Android Photo Picker."*
- `image_picker_android-0.8.13+17/CHANGELOG.md:183` (v0.8.11) — *"Updates documentation to note that Android Photo Picker use is not optional on Android 13+."*

**The shipped code does not do this.** With `useAndroidPhotoPicker = false`, `ACTION_GET_CONTENT` is fired unconditionally, on every API level. The README statement is not backed by any SDK-level branch in `ImagePickerDelegate`.

Practical consequence: the observed "Google Photos opens" behaviour is *consistent with* `ACTION_GET_CONTENT` resolution, and *inconsistent with* the photo picker (the photo picker UI is a system sheet, never the Google Photos app UI). So do not rely on the README claim — rely on the flag.

---

## Q2 — Does `useAndroidPhotoPicker` still exist in 0.8.13+17, what is the default, what changes?

**Yes. It still exists, and it defaults to `false`.**

`~/.pub-cache/hosted/pub.dev/image_picker_android-0.8.13+17/lib/image_picker_android.dart:20-23`

```dart
/// Sets [ImagePickerAndroid] to use Android 13 Photo Picker.
///
/// Currently defaults to false, but the default is subject to change.
bool useAndroidPhotoPicker = false;
```

It is threaded through as `usePhotoPicker` in `GeneralOptions` (Pigeon) and reaches `chooseImageFromGallery(options, usePhotoPicker, callback)`.

### What changes when enabled

| | `false` (default / current) | `true` |
|---|---|---|
| Intent | `ACTION_GET_CONTENT` (`image/*`) | `ActivityResultContracts.PickVisualMedia` (ImageOnly) |
| Native action on API 33+ | — | `MediaStore.ACTION_PICK_IMAGES` |
| UI | Whatever app owns the intent filter (Google Photos, OEM gallery, DocumentsUI) | System photo picker, half-screen bottom sheet, identical everywhere |
| Permissions | none | none |
| Process | third-party app launched | in-system picker |

The Dart side uses AndroidX `ActivityResultContracts.PickVisualMedia`, which per official Android docs:
> *"If the photo picker isn't available on a device, the library automatically invokes the `ACTION_OPEN_DOCUMENT` intent action instead. This intent is supported on devices that run Android 4.4 (API level 19) or higher."*
> — https://developer.android.com/training/data-storage/shared/photopicker

### Behavior on Android < 13 (backport)

- Photo picker availability: **Android 11+ with Google System Updates**; backport installable on **Android 4.4–10** and **Android Go 11/12** via **Google Play services**.
- **The backport trigger is already merged into this app's manifest by the plugin** — no app-side edit needed. `image_picker_android-0.8.13+17/android/src/main/AndroidManifest.xml:15-24`:

```xml
<!-- Trigger Google Play services to install the backported photo picker module. -->
<service android:name="com.google.android.gms.metadata.ModuleDependencies"
        android:enabled="false" android:exported="false" tools:ignore="MissingClass">
    <intent-filter>
        <action android:name="com.google.android.gms.metadata.MODULE_DEPENDENCIES" />
    </intent-filter>
    <meta-data android:name="photopicker_activity:0:required" android:value="" />
</service>
```

- If neither native nor backported picker is available → AndroidX falls back to **`ACTION_OPEN_DOCUMENT`** (system Documents UI). On such devices the multi-select `limit` is ignored (see `ImagePickerUtils.getMaxItems()` and the Android docs note).

---

## Q3 — Why does Google Photos appear at all? Is this a "default app" issue?

**Yes — it is Android intent resolution, not an app bug.**

Mechanics:

1. The plugin sends an **implicit** intent (`ACTION_GET_CONTENT`, no `setComponent`/`setPackage`).
2. Android's `PackageManager` resolves it among all activities declaring a matching `<intent-filter>` for `ACTION_GET_CONTENT` + `image/*`.
3. Because the plugin calls `startActivityForResult` **directly** (no `Intent.createChooser`), Android does not force a chooser:
   - exactly one matching handler → launched silently;
   - a default is set (by user or by OEM preconfiguration) → launched silently;
   - several handlers, no default → system shows the disambiguation dialog.
4. Google Photos ships with intent filters covering image viewing/picking (`ACTION_VIEW`, `ACTION_GET_CONTENT`, `ACTION_PICK` with `image/*`), and on Pixel/stock Android **there is no separate "Gallery" app at all** — Google Photos (plus Files) *is* the gallery. On many OEM builds Google Photos is also preconfigured as the default.

So: the app cannot guarantee which app answers an implicit pick intent. Fixing it is either (a) stop using an implicit pick intent (→ Photo Picker), or (b) user-side default-handler change (→ Q4d).

---

## Q4a — Solution A (recommended): enable the system Photo Picker

**Smallest possible change. No new runtime deps, no new permissions, no manifest edits.**

Put it in `main()` **before** `runApp`, and before any `image_picker` call (`ImagePickerPlatform.instance` is already the Android implementation at that point — plugin registration runs before the Dart entrypoint, and the official example does exactly this):

```dart
// lib/main.dart
import 'package:flutter/widgets.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final ImagePickerPlatform imagePickerImplementation = ImagePickerPlatform.instance;
  if (imagePickerImplementation is ImagePickerAndroid) {
    imagePickerImplementation.useAndroidPhotoPicker = true;
  }

  runApp(const PolochkaApp());
}
```

Credits: `~/.pub-cache/hosted/pub.dev/image_picker_android-0.8.13+17/README.md:16-36` and `example/lib/main.dart:26-36`.

⚠️ **Import note:** `image_picker_android` and `image_picker_platform_interface` are currently *transitive* dependencies. Importing them directly will trigger the `depend_on_referenced_packages` lint — add both to `pubspec.yaml` explicitly if you enable this.

### Behavior differences vs. today

| Aspect | Impact for this app |
|---|---|
| UI | Half-screen system bottom sheet; MediaStore items, newest first; "cloud media providers" (e.g. Google Photos cloud library) may appear as a source — but rendered *inside the system sheet*, not the Photos app |
| Album/folder browsing | Not available (flat list). Acceptable for a single product photo |
| `maxWidth` / `imageQuality` | **Still applied** — see Q5 |
| Permissions | None. No `READ_MEDIA_IMAGES`, no `READ_EXTERNAL_STORAGE` |
| Consistency | Identical UX on all devices — kills the Google Photos question permanently |
| `limit:` param | Only works when the flag is `true` (irrelevant here — single pick) |

---

## Q4b — Solution B: in-app gallery grid packages (alternatives)

These render **your own** grid from the device `MediaStore`, so the "which app opens" question disappears entirely.

| Package | Latest / age | Likes / points / downloads | Verdict for this app |
|---|---|---|---|
| **`photo_manager`** | `3.12.0`, ~3 months | 781 / — / — (verified `fluttercandies.com`) | Headless asset API (no UI). You build the grid yourself. Needs `READ_MEDIA_IMAGES` + `READ_MEDIA_VIDEO` (+ `READ_MEDIA_VISUAL_USER_SELECTED` on 14) and a permission flow + limited-access UI. Big lift for one image field |
| **`wechat_assets_picker`** | `10.1.3`, ~4 months | 872 / 155 / 59.9k (verified `fluttercandies.com`) | Complete WeChat-style picker UI on top of `photo_manager`. Zero custom UI work. Heavy transitive weight (`video_player`, `extended_image`, `provider`, `visibility_detector`). v10 requires **Flutter 3.27+**. Same media permissions required |
| **`gal`** | `3.0.1`, ~4 days | 599 / 160 / 769k | ❌ **Not a picker.** It *saves* images (`Gal.putImage`), and `Gal.open()` just opens the gallery app. Wrong tool |
| **`photo_view`** | — | — | ❌ **Not a picker.** A zoomable/pannable image *widget* for display |

**Do they still show Google Photos content?** They show the **`MediaStore` index**, not another app's UI. Photos that Google Photos has synced *into* local storage (DCIM/`Pictures`) appear. Cloud-only items that exist **only** inside Google Photos (not backed by a local `MediaStore` row) do **not** appear — `MediaStore` is the source of truth. So switching packages changes *coverage*, not just appearance.

Note: `photo_manager` docs also warn HEIC is poorly supported and recommend uploading the JPEG variant (`entity.file`).

---

## Q4c — Solution C: `ACTION_PICK` / `ACTION_OPEN_DOCUMENT` via platform channel

**`android_intent_plus` cannot do this.** It can *launch* intents but has **no `startActivityForResult` bridge**, so you can never receive the picked `Uri`. It is usable only for fire-and-forget intents (e.g. opening Settings).

A minimal `MethodChannel` in `MainActivity` is required:

```kotlin
// android/app/src/main/kotlin/.../MainActivity.kt
class MainActivity : FlutterActivity() {
    private var pendingResult: MethodChannel.Result? = null

    private val pickImage = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { res ->
        val uri = res.data?.data
        if (res.resultCode == RESULT_OK && uri != null) {
            // copy content:// to a cache file, then hand the path back
            pendingResult?.success(copyToCache(uri))
        } else {
            pendingResult?.success(null)
        }
        pendingResult = null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app/gallery")
            .setMethodCallHandler { call, result ->
                if (call.method == "pickWithDocumentsUi") {
                    pendingResult = result
                    pickImage.launch(
                        Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = "image/*"
                        }
                    )
                } else result.notImplemented()
            }
    }
}
```

Caveats:

- **`ACTION_PICK` is not a guarantee either.** It is still resolved by `PackageManager`, and Google Photos/OEM gallery may answer it. You may trade one ambiguity for another.
- **`ACTION_OPEN_DOCUMENT` is the most predictable**: it is handled by the system Documents UI (`com.android.documentsui`) and shows a real file browser, not Google Photos. This is exactly what AndroidX falls back to.
- Any content:// result still needs copying to a cache file before `image_cropper`/upload — which `image_picker` already does for you (see Q5). Re-implementing this is pure cost unless you have a hard requirement.
- Maintenance burden: a channel + native code paths you must test per API level/OEM.

---

## Q4d — Solution D: user changes the default handler in system settings

This is the only way to keep the *current* code path **and** change which app opens.

Steps (Android 12–14, near-stock):

1. **Settings → Apps → See all apps → Google Photos**
2. **Open by default** (a.k.a. *"Set as default"* / *"Defaults"*)
3. **Clear default preferences** / turn off *"Open supported links"* for image types
4. Alternatively **Settings → Apps → Default apps → Photos / Image viewer** and pick the OEM gallery
5. Next gallery pick → Android shows the *"Open with"* chooser; user picks the OEM gallery and may choose **"Just once"** to avoid re-setting a default

OEM paths vary (Samsung: *Settings → Apps → Choose default apps*). Some devices simply lack an alternative gallery app, in which case there is nothing to switch to.

**Why the app can't do this itself:**

- There is **no public API** to set or clear another app's default intent handler.
- The best an app can do is *open* the settings screen (`Settings.ACTION_MANAGE_DEFAULT_APPS_SETTINGS`) — a poor, easily-ignored UX.
- Hence: for a deterministic result, fix it in code (Q4a), not in settings.

---

## Q5 — Gotchas

### ✅ `maxWidth` / `imageQuality` are still honoured with the Photo Picker

This is the most common false assumption. `image_picker` **copies** the picked `content://` URI into the app cache and **then** resizes. Verified:

1. `FileUtils.getPathFromUri()` opens an `InputStream` via `ContentResolver` and writes a real file under `context.getCacheDir()/<uuid>/` → returns a **real filesystem path** (`FileUtils.java:62-103`).
2. `handleMediaResult()` → `getResizedImagePath()` → `ImageResizer.resizeImageIfNeeded(path, maxWidth, maxHeight, quality)` (`ImagePickerDelegate.java:902-923`).
3. `ImageResizer` decodes the file and re-encodes: **JPEG** unless the bitmap has alpha (then PNG) (`ImageResizer.java:178-184`).

So `maxWidth: 1600, imageQuality: 90` works identically for `ACTION_GET_CONTENT` and the Photo Picker.

### ✅ HEIC

`image_picker-1.2.2/lib/image_picker.dart:36-37` warns HEIC on Android 9+ works only *"if used in addition to a size modification"*. Because this app passes `maxWidth`, the resizer decodes → re-encodes to **JPEG**, neutralising HEIC.

⚠️ Cosmetic trap: the intermediate file keeps the *original* name with a `scaled_` prefix (`ImageResizer.java:81`), so you can get `scaled_IMG_1234.heic` containing JPEG bytes. Harmless here because `image_cropper` re-encodes to JPG (`compressFormat: ImageCompressFormat.jpg`) before upload.

### ✅ `READ_MEDIA_IMAGES` is *not* needed

- Photo Picker: per-item URI grant; no permission. (Android docs: the whole point is *"access to only selected images and videos, instead of their entire media library"*.)
- `ACTION_GET_CONTENT`: also permission-free.

The current manifest (no `READ_MEDIA_IMAGES` / `READ_EXTERNAL_STORAGE`) is **correct for both paths**. Do **not** add them — that would trigger Play Console's Photo & Video Permissions declaration.

### ⚠️ Android 14 "Selected photos access" partial permission

Relevant only if you go the `photo_manager` / `wechat_assets_picker` route (Q4b), where the app queries `MediaStore` directly:

- Requires `READ_MEDIA_IMAGES` (+ `READ_MEDIA_VIDEO`) and, for limited access, `READ_MEDIA_VISUAL_USER_SELECTED`.
- `photo_manager` returns `PermissionState.limited`; you must handle the "reselect" flow (`PhotoManager.presentLimited()`).
- With the Photo Picker or `ACTION_GET_CONTENT`, none of this applies.

### ✅ `image_cropper` / uCrop keeps working

`ImageCropper().cropImage(sourcePath: picked.path, ...)` needs a **real file path**. Because `FileUtils.getPathFromUri()` always materialises a cache file, `picked.path` is a normal path (never `content://`) on both picker paths. **No change needed** to `_cropImage()`.

Two follow-ons:
- `cropped.path` is uCrop's own temp file; `cropped.path.split('/').last` is fine.
- Cache lifecycle: `image_picker` writes into `cacheDir` and `uCrop` writes its own temp file. Both are transient — the app already persists the bytes immediately via `saveImageBytes`, which is the right pattern.

### ⚠️ Process death while the picker is open (existing latent bug, picker-independent)

Android can kill `MainActivity` while the external picker activity is foregrounded. The app **never calls `ImagePicker.retrieveLostData()`** (`grep` over `lib/` → no matches). On low-memory devices the user can pick a photo and get **nothing back**, silently.

`image_picker-1.2.2/README.md:49-80` recommends checking at startup:

```dart
final LostDataResponse response = await ImagePicker().retrieveLostData();
if (!response.isEmpty && response.files != null) {
  // re-offer the image to the user
}
```

Worth fixing regardless of which picker option you choose.

---

## Recommendation (ranked)

1. **Set `useAndroidPhotoPicker = true` in `main()`** (Q4a). One flag, ~6 lines, no new runtime deps, no permissions, no manifest changes; keeps `maxWidth`/`imageQuality`/uCrop working; makes the UI identical on every device and permanently removes the Google Photos question.
   - Add `image_picker_android` + `image_picker_platform_interface` to `pubspec.yaml` to satisfy `depend_on_referenced_packages`.
   - Keep an eye on the plugin's note that the flag's *default* is "subject to change" — when it flips, you can drop the code.
2. If you truly need a **folder/album** UI → `wechat_assets_picker` (accept the media permissions + dependency weight).
3. Only if a specific OEM gallery must be used → custom `ACTION_OPEN_DOCUMENT` channel (Q4c). `ACTION_PICK` and `android_intent_plus` do not solve it.
4. Never rely on asking the user to change defaults (Q4d) as the primary fix.

## Key Findings

- `pickImage(gallery)` with the default flag fires a bare **`ACTION_GET_CONTENT` + `image/*`**, via `startActivityForResult`, **without** `Intent.createChooser` — so Android's default-handler resolution decides, not the app.
- `useAndroidPhotoPicker` **exists and is still `false` by default** in 0.8.13+17, despite README claims that Android 13+ "uses the Photo Picker" automatically. Code contradicts docs.
- The GMS Photo Picker **backport service is already declared in the plugin's manifest** and merges into the app — nothing to add.
- `maxWidth`, `imageQuality`, HEIC handling and `image_cropper` are **all unaffected** by switching, because `image_picker` copies to a cache file before resizing.
- `gal` and `photo_view` are **not image pickers** — commonly conflated; corrected here.

## Related Systems

- [`image_cropper`](https://pub.dev/packages/image_cropper) — uCrop on Android, consumes the cache path produced by `image_picker`
- Android Photo Picker (`ActivityResultContracts.PickVisualMedia` / `MediaStore.ACTION_PICK_IMAGES`)
- Android intent resolution & default handlers
- [`photo_manager`](https://pub.dev/packages/photo_manager) / [`wechat_assets_picker`](https://pub.dev/packages/wechat_assets_picker) — MediaStore-backed in-app grids

## Related Documentation

- [Android Photo Picker (official)](https://developer.android.com/training/data-storage/shared/photopicker) — availability, `ACTION_OPEN_DOCUMENT` fallback, backport manifest entry, no permissions needed, `getPickImagesMaxLimit()`
- [`ActivityResultContracts.PickVisualMedia` reference](https://developer.android.com/reference/kotlin/androidx/activity/result/contract/ActivityResultContracts.PickVisualMedia)
- [image_picker_android README — Photo Picker section](https://pub.dev/packages/image_picker_android) — flag usage + `limit` requirement
- [image_picker README — handling MainActivity destruction](https://pub.dev/packages/image_picker) — `retrieveLostData`
- [image_picker_android CHANGELOG](https://pub.dev/packages/image_picker_android/changelog) — `usePhotoPickerAndroid` added in 0.8.6; `limit` in 0.8.10; 0.8.11 doc claim
- [photo_manager README — Android 13/14 permission config](https://pub.dev/packages/photo_manager)
- [wechat_assets_picker README — permissions & Flutter compatibility matrix](https://pub.dev/packages/wechat_assets_picker)
- [gal](https://pub.dev/packages/gal) — save-to-gallery only (`Gal.putImage`, `Gal.open`)

## Source files inspected (local, authoritative for 0.8.13+17)

- `~/.pub-cache/hosted/pub.dev/image_picker_android-0.8.13+17/lib/image_picker_android.dart` (lines 20-23, 62-120)
- `.../android/src/main/java/io/flutter/plugins/imagepicker/ImagePickerDelegate.java` (305-337, 432-497, 706-744, 882-923)
- `.../ImagePickerUtils.java` (60-88)
- `.../FileUtils.java` (62-103)
- `.../ImageResizer.java` (36-74, 178-184)
- `.../android/src/main/AndroidManifest.xml` (15-24)
- `~/.pub-cache/hosted/pub.dev/image_picker-1.2.2/README.md` (49-94), `lib/image_picker.dart` (36-37)
- Repo: `beauty_shelf_app/lib/widgets/product_form.dart` (165-269), `android/app/src/main/AndroidManifest.xml`
