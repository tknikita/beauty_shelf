---
source: Local plugin source (pub cache) + Xiaomi HyperOS developer docs + AOSP MediaProvider + GitHub issues + Chinese dev write-ups + MIUI user forums
topic: Xiaomi MIUI/HyperOS gallery image-picking behaviour (ACTION_PICK vs Photo Picker)
systems: image_picker, image_picker_android, file_picker, image_cropper, com.miui.gallery, Android Photo Picker, ACTION_PICK, ACTION_GET_CONTENT, ACTION_PICK_IMAGES, HyperOS, MIUI
created: 2026-11-19
last-verified: 2026-11-19
researcher: ResearchAgent
project: beauty_shelf
tags: [flutter, android, image-picker, miui, hyperos, xiaomi, action-pick, photo-picker, ucrop, intent-resolution]
---

# Research: Xiaomi MIUI / HyperOS gallery image-picking behaviour

> **Companion doc:** [`./android-gallery-vs-google-photos.md`](./android-gallery-vs-google-photos.md) — covers what `image_picker_android` 0.8.13+17 actually fires (`ACTION_GET_CONTENT`, no chooser), the `useAndroidPhotoPicker` flag, and why `maxWidth`/uCrop keep working. This document assumes that and only answers the **Xiaomi-specific** questions.

## Legend — how confident each claim is

| Mark | Meaning |
|---|---|
| ✅ **VERIFIED** | Read in source code / official docs during this session, or directly observed in a first-party document |
| 🟡 **BEHAVIOURAL** | Reported by real MIUI/HyperOS users or dev write-ups; consistent across sources, but not a spec |
| ⚠️ **UNCERTAIN** | Could **not** be verified from public sources; stated as a hypothesis + a command to check it on-device |

**Big honesty caveat up front:** the actual `<intent-filter>` list of `com.miui.gallery` was **not** obtainable from public sources in this session (no decompiled manifest, no OEM doc). Everything about *which filters it declares* is therefore 🟡/⚠️. Everything about *what actually happens on MIUI devices* is 🟡 with links. Section **Q1b** gives the exact `adb` commands to settle it in 30 seconds on the user's phone.

---

## Context (this repo, confirmed by reading local files)

| Item | Value | Source |
|---|---|---|
| `image_picker` / `image_picker_android` | 1.2.2 / 0.8.13+17 | `pubspec.yaml`, `pubspec.lock` |
| `image_cropper` | **8.1.0** | `pubspec.lock` |
| `file_picker` | **^8.0.0** (already a dependency, used by `backup_service.dart`) | `pubspec.yaml:45` |
| Current behaviour | `useAndroidPhotoPicker = true` in `main.dart:17-20` → `MediaStore.ACTION_PICK_IMAGES` | `lib/main.dart` |
| `retrieveLostData` | **Already implemented** via `ImageRecovery` (`lib/services/image_recovery.dart`), called at startup and on resume | `lib/main.dart:23,69` |
| `image_cropper` API | `cropImage({required String sourcePath, ...})` — **file path only, not `Uri`** | `image_cropper-8.1.0/lib/src/cropper.dart:54-68` |

> The last row matters: any native picker you write must **materialise a real file**, because `image_cropper` 8.x cannot consume a `content://` URI.

---

## Q1 — Which intent does Xiaomi Gallery (`com.miui.gallery`) register for picking a single image?

### What is actually known

✅ **VERIFIED (launcher component):** `com.miui.gallery/com.miui.gallery.activity.HomePageActivity` is the Gallery launcher activity — confirmed independently in three icon-pack `appfilter.xml` files indexed on grep.app ([WSTxda/Lineage-Icons](https://github.com/WSTxda/Lineage-Icons), [zixpo/candybar](https://github.com/zixpo/candybar), [Donnnno/candybar-foss](https://github.com/Donnnno/candybar-foss)). **This is the launcher, not the picker** — see Q5.

🟡 **BEHAVIOURAL (ACTION_PICK is answered by Xiaomi's gallery):** A widely-copied Chinese dev write-up documents the classic Xiaomi trap:

> "除了小米，用 ACTION_PICK，都能得到一个图片的绝对路径。如果是小米，用 ACTION_PICK，就需要去转化了。但是，小米用 ACTION_GET_CONTENT 或者 ACTION_OPEN_DOCUMENT，低版本，也能得到绝对路径。最后统一的处理方法就是，用 ACTION_GET_CONTENT…"
>
> *"Except on Xiaomi, `ACTION_PICK` gives you an absolute path. On Xiaomi, `ACTION_PICK` needs conversion. But on Xiaomi, `ACTION_GET_CONTENT` or `ACTION_OPEN_DOCUMENT` gives an absolute path on low versions. The unified fix: use `ACTION_GET_CONTENT`."*
> — [cnblogs.com/manmanlu/p/6589151.html](https://www.cnblogs.com/manmanlu/p/6589151.html) (2017, mirrors CSDN)

Interpretation: on Xiaomi devices, `ACTION_PICK` **is** handled, and it returns a **MediaStore-style encoded `content://` URI** (authority `media`, `_id` path segment) rather than a `file://` path. That is the signature of the phone's own gallery answering the intent. This is the strongest public evidence that MIUI Gallery declares `ACTION_PICK` for `image/*` — and it also means **the returned URI must be copied via `ContentResolver`**, which is exactly what Q4's code does.

🟡 **BEHAVIOURAL (GET_CONTENT is answered by Xiaomi Gallery):** Two independent MIUI users report that an app's "add file / add photo" action opens **Xiaomi's Gallery directly, with no chooser**, even after changing Default apps:

> "Clicking the 'add files' will not prompt any choices but instead Diarium opens straight to Gallery. Changing the default app also doesn't work."
> "I use a Xiaomi phone which also uses MIUI. The Add File also opens Xiaomi's Gallery. I tried changing the Default Apps to use a different Gallery app but Xiaomi insists on using Xiaomi's own Gallery. It seems hardcoded by Xiaomi."
> — [forum.diariumapp.com thread 4645](https://forum.diariumapp.com/d/4645-how-to-fix-the-button-add-file-to-open-file-manager-instead-of-gallery) (MIUI Global 14.0.1, POCO F2 Pro + second Xiaomi user)

⚠️ **UNCERTAIN:** the exact filter set. Best-supported reconstruction:

| Action | Category | Data | Likely on `com.miui.gallery`? | Confidence |
|---|---|---|---|---|
| `android.intent.action.PICK` | `DEFAULT` | `image/*` (and `video/*`) | **Yes** — classic OEM-gallery filter; behaviour matches | 🟡 high |
| `android.intent.action.GET_CONTENT` | `DEFAULT` (usually **without** `OPENABLE`) | `image/*` | **Probably yes** — required to explain the Diarium reports | 🟡 medium |
| `android.intent.action.VIEW` | `DEFAULT` | `image/*`, `video/*` | Yes (it's an image viewer) | ✅ high (implied by it being the default viewer) |
| `android.intent.action.PICK_IMAGES` | — | — | **Not on MIUI/HyperOS 1–2.** On HyperOS 3+/Android 16 the OEM picker is documented via this action, but the handler component is not stated (see Q7) | ⚠️ |

Note that `CATEGORY_OPENABLE` is **not** what `PICK` uses — it is an `ACTION_GET_CONTENT`/`OPEN_DOCUMENT` concept (it restricts results to things openable as a stream). `image_picker_android` deliberately does **not** add it (`ImagePickerDelegate.java:53-54` — just `ACTION_GET_CONTENT` + `setType("image/*")`).

### Q1b — How to settle Q1 definitively (run on the user's phone)

This is the authoritative, 30-second answer. `pm query-activities` is what Google's own AOSP PhotoPicker README recommends for this exact kind of debugging ([AOSP photopicker/README](https://android.googlesource.com/platform/packages/providers/MediaProvider/+/HEAD/photopicker/README)).

```bash
# 1. Who answers a plain gallery pick?
adb shell pm query-activities -a android.intent.action.PICK -t "image/*"

# 2. Who answers GET_CONTENT for images? (note priority/default flags)
adb shell pm query-activities -a android.intent.action.GET_CONTENT -t "image/*"

# 3. Who answers the system Photo Picker?
adb shell pm query-activities -a android.provider.action.PICK_IMAGES -t "image/*"

# 4. Full declared filter list + activity names for the Gallery app
adb shell dumpsys package com.miui.gallery | grep -iE "Activity|IntentFilter|action\.|mimeType|priority"

# 5. Which OS branch are we even on?
adb shell getprop ro.mi.os.version.name
adb shell getprop ro.build.version.release
```

Step 4's output *is* the manifest's intent-filter set — that is the ground truth, no decompilation needed. **Recommend running it before writing any code.**

---

## Q2 — On MIUI/HyperOS with BOTH Xiaomi Gallery and Google Photos installed, what wins?

There is no single answer, and that is the point. There are **two conflicting bodies of evidence**, and they are both real:

| Observation | Device / context | Source |
|---|---|---|
| Bare `ACTION_GET_CONTENT` + `image/*` → **Google Photos** | This app's user's Xiaomi phone, before `useAndroidPhotoPicker = true` | Issue report (this repo's context) |
| Bare `ACTION_GET_CONTENT` → **Xiaomi Gallery**, no chooser, defaults can't be changed | MIUI Global 14.0.1, POCO F2 Pro + a second Xiaomi user | [Diarium forum 4645](https://forum.diariumapp.com/d/4645-how-to-fix-the-button-add-file-to-open-file-manager-instead-of-gallery) |

**Resolution of the apparent contradiction:** both are consistent with ordinary Android intent resolution. Whoever holds the **default/preferred handler** for that action+type wins silently. Google Photos can hold it (e.g. user granted it while setting up backup, or MIUI's "Default apps → Gallery" was pointed at Photos); Gallery can hold it (MIUI factory default on most units). The Diarium users' "changing defaults doesn't work" is consistent with MIUI's Default-apps screen **not** exposing the `GET_CONTENT` handler — MIUI's Default Apps page mainly controls `VIEW`/home/phone/SMS, not `GET_CONTENT`. Not a contradiction, just an unhelpful settings UI.

### What about bare `ACTION_PICK` + `image/*`?

⚠️ **UNCERTAIN, but the balance of evidence says Gallery wins and Google Photos is not even in the running.** Two independent reasons:

1. **Google Photos does not appear to declare `ACTION_PICK`.** The canonical way to target Google Photos specifically is `ACTION_GET_CONTENT` + `setPackage("com.google.android.apps.photos")`, not `PICK` (see [SO 32341573](https://stackoverflow.com/questions/32341573/how-to-pick-image-from-google-photos-app-only-android-google-photos-intent), and Google Photos' returned URIs use authority `com.google.android.apps.photos.content`, handled as a special case in the Xiaomi helper code above). No public source shows a `PICK` filter for it.
2. **On devices with no gallery at all, `ACTION_PICK` throws `ActivityNotFoundException`** — which only makes sense if the action has a narrow handler set (OEM galleries), not a broad one including Photos. Reports: [SO 66312517](https://stackoverflow.com/questions/66312517/no-activity-found-to-handle-intent-intent-action-pick) (Android 9), [jrvansuita/PickImage#109](https://github.com/jrvansuita/PickImage/issues/109) (`act=android.intent.action.PICK typ=image/*`, Motorola G4 Plus, no gallery preinstalled).

**Practical conclusion for this app:** switching from `GET_CONTENT` to `ACTION_PICK` removes Google Photos from the competition in practice, and on MIUI it should land in Xiaomi Gallery. But because the no-handler case is real, `ACTION_PICK` **must** be wrapped in a fallback (Q4) or it will crash on some devices.

---

## Q3 — Is there a maintained Flutter package that opens the OEM gallery directly?

Short answer: **yes, and you already depend on it — `file_picker`.**

✅ **VERIFIED — `file_picker` deliberately fires `ACTION_PICK` for image picking.** Two versions read from the local pub cache:

`file_picker-10.3.10/android/src/main/kotlin/com/mr/flutter/plugin/filepicker/FileUtils.kt:153-158`
```kotlin
if (type == "image/*") {
    // Use ACTION_PICK for images to allow using the Gallery app, which provides a better UX for image selection.
    intent = Intent(Intent.ACTION_PICK)
    val uri = (Environment.getExternalStorageDirectory().path + File.separator).toUri()
    intent.setDataAndType(uri, type)
    intent.type = this.type          // NB: setType() clears the data URI set above
    ...
```

`file_picker-8.3.7/.../FilePickerDelegate.java:247-248` (the version this app resolves) is the same logic:
```java
if (type.equals("image/*")) {
    intent = new Intent(Intent.ACTION_PICK, android.provider.MediaStore.Images.Media.EXTERNAL_CONTENT_URI);
```
Both then guard with `intent.resolveActivity(activity.getPackageManager()) != null` and fail with `invalid_format_type` instead of crashing.

`FileType.image` maps to `"image/*"` (`file_picker-10.3.10/.../FilePickerPlugin.kt:40`), and `FileUtils` copies the resulting `content://` URI into `cacheDir/file_picker/...` (`FileUtils.java:257-303`), so you get a **real file path** — usable directly by `image_cropper` 8.1.0.

So the minimal Dart call is:

```dart
final res = await FilePicker.platform.pickFiles(
  type: FileType.image,
  allowMultiple: false,
  withData: false,
);
final path = res?.files.single.path; // null if user cancelled
```

### Package comparison for a single-image, crop-then-attach flow

| Approach | Opens OEM Gallery? | New deps / permissions | Extra work | Verdict |
|---|---|---|---|---|
| **`file_picker`** `FileType.image` | ✅ **Yes — `ACTION_PICK`** | none (already present) | ~5 lines in `product_form.dart` | **Least invasive by far** |
| **Small `MethodChannel` + `ACTION_PICK`** | ✅ Yes, and you control flags/fallback/errors | ~80 lines Kotlin, 1 Dart wrapper | medium | Best if you need a guaranteed fallback chain + logging |
| `image_picker` (status quo / Photo Picker) | ❌ No — system sheet | none | none | Deterministic, but not what the user asked for |
| `photo_manager` + custom grid | ❌ No — in-app `MediaStore` grid | `READ_MEDIA_IMAGES` (+ `READ_MEDIA_VIDEO`, `READ_MEDIA_VISUAL_USER_SELECTED` on 14) | large (permissions flow + UI) | Overkill |
| `wechat_assets_picker` | ❌ No — in-app WeChat-style grid | same media permissions as above; heavy transitive deps | small code, big bundle | Overkill, and still not "Gallery" |
| `android_intent_plus` | launches, but **cannot receive the result** | — | — | ❌ Not a picker (no `startActivityForResult`) |

### `file_picker` caveats you must know before choosing it

1. 🟡 **Undocumented-from-Dart-perspective behaviour.** It is intentional in the plugin's *native* code (there's even a comment saying so in 10.x), but it is not in the README's contract. Pin the dependency (`file_picker: 8.3.7`) or add a regression test, since a future major could switch to `ACTION_OPEN_DOCUMENT`.
2. 🟡 **Package-visibility guard.** `file_picker`'s own manifest only declares a `<queries>` entry for `GET_CONTENT` + `*/*` (`file_picker-8.3.7/android/src/main/AndroidManifest.xml:3-8`), **not** for `ACTION_PICK`. On Android 11+ `resolveActivity(ACTION_PICK)` returns `null` for packages the app cannot see. In practice Galleries also declare `GET_CONTENT`, so the gallery is visible and this works — but it is an indirect dependency. If you ever see `invalid_format_type` on some OEM, this is why.
3. ⚠️ **No resizing.** You lose `maxWidth: 1600, imageQuality: 90` (which `image_picker` applied via `ImageResizer`). uCrop can do it instead (`maxWidth:` param on `cropImage`), or add `image`/`flutter_image_compress`. For a single product photo this is acceptable — the crop step already re-encodes to JPEG.
4. ✅ Returns a cache path, not `content://` → `image_cropper` works unchanged.

---

## Q4 — Minimal `MethodChannel` implementation (if you want full control)

Needed only if you want your own fallback chain, error codes, and telemetry. Reference implementation — **`ACTION_PICK` + copy-to-cache**:

```kotlin
// android/app/src/main/kotlin/<your/package>/MainActivity.kt
package com.example.polochka   // keep the real package

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import androidx.activity.result.contract.ActivityResultContracts
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException
import java.util.UUID
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private var pending: MethodChannel.Result? = null
    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    // Registered here: called from onCreate (via FlutterActivity), i.e. before STARTED.
    private val pickLauncher =
        registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { res ->
            val result = pending ?: return@registerForActivityResult
            pending = null

            if (res.resultCode != Activity.RESULT_OK) { result.success(null); return@registerForActivityResult }

            // Some OEMs return the URI in clipData even for single picks; handle both.
            val uri: Uri? = res.data?.data
                ?: res.data?.clipData?.takeIf { it.itemCount > 0 }?.getItemAt(0)?.uri
            if (uri == null) { result.success(null); return@registerForActivityResult }

            io.execute {
                try {
                    val file = copyToCache(uri)
                    main.post { result.success(file.absolutePath) }
                } catch (t: Throwable) {
                    main.post { result.error("copy_failed", t.message, null) }
                }
            }
        }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "beauty_shelf/image_pick")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickFromGallery" -> {
                        if (pending != null) {
                            result.error("busy", "A pick is already in flight", null); return@setMethodCallHandler
                        }
                        val intent = Intent(Intent.ACTION_PICK).apply {
                            // setDataAndType, NOT "new Intent(action, uri)" + setType():
                            // setType() clears the data URI, leaving a bare type-only intent.
                            setDataAndType(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, "image/*")
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        }
                        // Package visibility (Android 11+): may be null even if a handler exists -> see caveat.
                        if (intent.resolveActivity(packageManager) == null) {
                            result.error("no_handler", "No app handles ACTION_PICK image/*", null)
                            return@setMethodCallHandler
                        }
                        pending = result
                        pickLauncher.launch(intent)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun copyToCache(uri: Uri): File {
        val mime = contentResolver.getType(uri)
        val ext = when (mime) {
            "image/png" -> "png"
            "image/webp" -> "webp"
            "image/heic", "image/heif" -> "heic"
            "image/gif" -> "gif"
            else -> "jpg"
        }
        val dir = File(cacheDir, "picked").apply { mkdirs() }
        val out = File(dir, "pick_${UUID.randomUUID()}.$ext")
        val input = contentResolver.openInputStream(uri)
            ?: throw IOException("openInputStream() returned null for $uri")
        input.use { ins -> out.outputStream().use { ins.copyTo(it, 64 * 1024) } }
        return out
    }
}
```

Dart side:

```dart
static const _ch = MethodChannel('beauty_shelf/image_pick');

Future<String?> pickFromXiaomiGallery() async {
  try {
    return await _ch.invokeMethod<String>('pickFromGallery');
  } on PlatformException catch (e) {
    if (e.code == 'no_handler') return null; // -> fall back to image_picker
    rethrow;
  }
}
```

### Pitfalls (all real, ordered by how likely they are to bite)

| # | Pitfall | Detail / mitigation |
|---|---|---|
| 1 | **`setType()` silently clears the data URI** | `Intent(ACTION_PICK, uri)` then `.type = "image/*"` ends up with `data == null`. Use `setDataAndType(uri, "image/*")` if you want the directory hint. (`file_picker` gets this "wrong" and still works — a bare type-only `PICK` is accepted in practice.) |
| 2 | **`resolveActivity()` lies on API 30+** | Package visibility. An intent that will launch fine can resolve to `null`. Either accept possible false negatives, declare `<queries><intent><action android:name="android.intent.action.PICK"/><data android:mimeType="image/*"/></intent></queries>`, or just `try { launch } catch (ActivityNotFoundException)`. `startActivityForResult` itself is **not** blocked by visibility. |
| 3 | **`I/O` on the main thread → ANR on large/cloud photos** | `openInputStream` for a 50 MB photo over a cloud provider can block. Copy on a background executor and post the result back (as above). `MethodChannel.Result` must be invoked on the platform main thread. |
| 4 | **Result can be `null` even after a successful pick** | Xiaomi-specific: several Chinese write-ups (e.g. "小米手机相册选取后的intent为空") report `RESULT_OK` with `data == null` / `getData() == null` on MIUI. Handle `uri == null` as cancel, never assume. |
| 5 | **`_data` / `MediaStore.Images.Media.DATA` is not a path** | The classic crash (`cursor.moveToFirst()` on a null cursor) comes from reading `DATA`. On Xiaomi `ACTION_PICK` returns an encoded id, not a path. **Never** resolve a path — stream the bytes via `ContentResolver`. |
| 6 | **Google Photos URIs use their own authority** | `com.google.android.apps.photos.content` — another reason to always go through `openInputStream`, never `File(uri.path)`. |
| 7 | **Persistable permissions don't apply** | `ACTION_PICK` / `ACTION_GET_CONTENT` grants are **one-shot**. `takePersistableUriPermission()` will throw unless the intent carried `FLAG_GRANT_PERSISTABLE_URI_PERMISSION` (only meaningful for `ACTION_OPEN_DOCUMENT`). Correct pattern: copy to cache immediately, as above. |
| 8 | **`FLAG_GRANT_READ_URI_PERMISSION`** | Add it anyway; some providers only grant when it is set. Harmless. |
| 9 | **`CATEGORY_OPENABLE`** | Do **not** add it to `ACTION_PICK` with a MediaStore URI — it's a `GET_CONTENT` concept and can exclude some handlers. (`image_picker` correctly omits it.) |
| 10 | **`MAXSIZE` / bitmap limits** | If you ever decode yourself, use `BitmapFactory.Options.inJustDecodeBounds` + `inSampleSize`. Not needed here — you hand a file to uCrop, which has `maxWidth`. |
| 11 | **EXIF orientation** | Not a problem while you pass the original file to uCrop (uCrop honours EXIF). It *becomes* a problem the moment you start downscaling/re-encoding yourself before cropping. |
| 12 | **Process death while the picker is foregrounded** | `image_picker`'s `retrieveLostData()` does **not** cover your custom channel. `pending` is lost on activity recreation → the user picks a photo and nothing happens. Persist a "pick in flight" flag and re-check on resume, or accept the risk (this app already has `ImageRecovery` for the `image_picker` path only). |
| 13 | **Request-code collisions** | Don't use `onActivityResult(int,int,Intent)` with a magic int — other plugins share `FlutterActivity`. `registerForActivityResult` (as above) avoids this. |
| 14 | **Cache growth** | Copies land in `cacheDir/picked/`. Prune on startup (they're small, but unbounded). |

---

## Q5 — Is hardcoding `Intent.setComponent("com.miui.gallery", ...)` viable?

**No. Do not do it.** Four independent reasons:

1. ✅ **The one component name that *is* publicly verifiable is the launcher**, `com.miui.gallery.activity.HomePageActivity` (see Q1). It opens the Gallery home screen — it does **not** run a pick flow, so it will never `setResult()` and your `pending` result hangs forever / returns `RESULT_CANCELED`.
2. ⚠️ **The actual picker activity name is not publicly documented and is version-specific.** Even if you reverse-engineer it on one HyperOS build, `setComponent` bypasses intent filtering entirely — a rename in the next Gallery update produces `ActivityNotFoundException` on real users, not at build time.
3. ✅ **On any non-Xiaomi device it throws immediately.** `com.miui.gallery` does not exist on Samsung/Huawei/Pixel/AOSP; `setComponent` + `startActivity` → `ActivityNotFoundException`. You would need a `try/catch` + existence check by package name, and the existence check needs `<queries>` on API 30+ (`PackageManager.getPackageInfo` is filtered too).
4. 🟡 **MIUI may gate cross-app gallery access behind a signature permission.** Chinese write-ups reference a `com.miui.gallery.open` permission in the crash path of third-party pick flows; if certain Gallery activities are `permission`-protected, `setComponent` would be blocked even on a Xiaomi device. ⚠️ Unverified — but it is another reason not to reach into another app's internals.

**Correct approach instead:** an *implicit* intent (`ACTION_PICK`), letting the OS pick the handler, with a fallback. If you truly must guarantee "Xiaomi Gallery or nothing", the honest UI is a chooser (Q6).

---

## Q6 — Does `Intent.createChooser(...)` reliably surface Xiaomi Gallery?

🟡 **Yes for discovery, but it has a known MIUI-specific landmine.**

- A chooser forces the disambiguation dialog, so **every** app declaring the action+type is listed, including Xiaomi Gallery. This is the only *intent-based* way to guarantee the user sees Gallery as an option. `ACTION_GET_CONTENT` wrapped in a chooser is the classic "show me all galleries" recipe.
- **Cost:** one extra tap on **every** pick (the chooser is unconditional; you lose the "single handler → launch silently" and "user has a default → launch silently" fast paths). The system also offers *Just once / Always*, so a user can pin Gallery and then… still get a chooser next time, because `createChooser` always shows the sheet.
- 🟡 **MIUI 12 / Android 11 bug:** `createChooser` around a content intent returns `RESULT_CANCELED` on some MIUI builds. This is the root cause of [CanHub/Android-Image-Cropper#253](https://github.com/CanHub/Android-Image-Cropper/issues/253) — a pinned bug titled *"MIUI (Xiaomi) cant pick image from gallery"*, where the reporter's log shows `E/Camera Error:: picking image failed` right after the chooser, and the workaround adopted by users was *"skip the chooser and just use the first found camera/gallery app"*. Linked SO: [SO 67785661](https://stackoverflow.com/questions/67785661/taking-and-picking-photos-on-poco-x3-with-android-11-does-not-work).
  - Note the maintainer's conclusion: it is **not** an Android-wide problem — it is MIUI-specific, and the fix belongs in an OEM check, not in everyone's code path.

**Verdict:** chooser is a decent *fallback*, a poor *default*. And on the exact OEM you are trying to satisfy, it is the option with the worst bug history.

---

## Q7 — Does HyperOS/MIUI ship its own photo picker? Does `com.miui.gallery` handle `ACTION_PICK_IMAGES`?

✅ **VERIFIED — Xiaomi now officially documents `MediaStore.ACTION_PICK_IMAGES` as *the* photo picker for HyperOS 3+.** From Xiaomi's own HyperOS developer platform, page *"照片视频选择控件"* (Photo/video selection control), last updated 2026-01-12:

> **三、适用范围** — 当前支持 PhotoPicker 的操作系统版本如下：
> - ColorOS 16（基于 Android 16）及以上
> - HyperOS 3（基于 Android 16）及以上
> - OriginOS 6（基于 Android 16）及以上
> - MagicOS 10（基于 Android 16）及以上
>
> **4.1 Action: `MediaStore.ACTION_PICK_IMAGES`** — 该 action 仅适用于图片/视频，请求方能读取选中图片/视频的数据，**无需申请读权限**。
> Returns: `picker uri` … `DATA` field is rewritten, not a real public path (`…/.transforms/synthetic/picker/0/com.android.providers.media.photopicker/media/xx`)
>
> *The adaptation guide is identical to the ITGSA ("金标联盟") published guide.*

Source: [dev.mi.com/xiaomihyperos/documentation/detail?pId=2221](https://dev.mi.com/xiaomihyperos/documentation/detail?pId=2221) · ITGSA doc: [itgsa.com/doc/6631953378231296](https://www.itgsa.com/doc/6631953378231296)

Implications, which are somewhat awkward for the user's request:

- **On HyperOS 3 / Android 16+, the "system Photo Picker" is the OEM-sanctioned, jointly-standardised picker** across Xiaomi/OPPO/vivo/Honor/OnePlus. It is not a Google imposition; it is the direction the Chinese OEMs agreed on.
- ⚠️ **On HyperOS 1–2 / Android 13–15**, `ACTION_PICK_IMAGES` is served by AOSP MediaProvider (on GMS devices, the `com.google.android.providers.media.module` package the user is seeing). This matches the reported component `com.google.android.providers.media.module/...PhotoPickerActivity` → **the user's phone is almost certainly ≤ Android 15**.
- ✅ **AOSP's picker also answers plain `ACTION_GET_CONTENT` for images.** From the MediaProvider PhotoPicker README:
  > "Launching `ACTION_PICK_IMAGES` or `ACTION_GET_CONTENT` should bring you into the new PhotopickerActivity."
  and it recommends exactly the `adb shell pm query-activities -a "android.intent.action.GET_CONTENT" -t "image/*"` command for debugging.
  → [android.googlesource.com …/photopicker/README](https://android.googlesource.com/platform/packages/providers/MediaProvider/+/HEAD/photopicker/README)

  That is a subtle but important point: **"bare `GET_CONTENT` → Google Photos" is not guaranteed on Android 13+ at all.** On stock Android 13+ the Photo Picker often intercepts `GET_CONTENT` for images; it lands in Google Photos only when Photos holds the default handler for that action+type.
- ⚠️ **Does `com.miui.gallery` handle `ACTION_PICK_IMAGES`?** Not documented anywhere I could find. Xiaomi's doc names the *action*, never the *component*. Treat as unknown; the `pm query-activities` command in Q1b answers it.

---

## Q8 — Does Google Photos aggressively claim default for `ACTION_PICK`?

⚠️ **No evidence that it claims `ACTION_PICK` at all.** Everything public points the other way:

- The recommended way to *force* Google Photos is `ACTION_GET_CONTENT` (+ `setPackage`) — see [SO 32341573](https://stackoverflow.com/questions/32341573/how-to-pick-image-from-google-photos-app-only-android-google-photos-intent).
- Google Photos' picker returns `content://com.google.android.apps.photos.content/...` URIs — again the `GET_CONTENT` family, which is why every Android `Uri`-to-path helper has an `isGooglePhotosUri()` special case.
- `ACTION_PICK` on devices lacking an OEM gallery throws `ActivityNotFoundException`, which would be impossible if Google Photos were a universal `PICK` handler.

Its **`ACTION_VIEW` / `ACTION_GET_CONTENT`** default-handler claim is real and aggressive (that is exactly what bit this app before `useAndroidPhotoPicker = true`). 🟡 Some OEM ROMs also pre-point the system "Gallery" default at Photos.

**Consequence:** changing the intent action from `ACTION_GET_CONTENT` to `ACTION_PICK` is a targeted fix for *this specific* symptom (Google Photos winning), because it changes the action Photos competes for. It is **not** a general improvement — it trades a well-supported action for a legacy one that can have zero handlers.

---

## Ranked recommendation for this app

### 1️⃣ Switch to `ACTION_PICK` with a hard fallback to the Photo Picker — best UX match
Use `file_picker` (`FileType.image`) or the MethodChannel from Q4. On cancel/failure (`invalid_format_type` / `no_handler` / `ActivityNotFoundException`) fall back to `ImagePicker` with `useAndroidPhotoPicker = true`.

- **Pros:** opens Xiaomi Gallery on MIUI (what the user asked for); Google Photos is effectively out of the picture; no new permissions; no manifest changes; `image_cropper` keeps working because a real file path comes back; **zero native code if you use `file_picker`** (already a dependency).
- **Cons:** legacy action → must handle "no handler" on devices without a gallery; loses `image_picker`'s built-in `maxWidth`/`imageQuality` (move to uCrop's `maxWidth`); relies on `file_picker`'s native behaviour (pin the version); two code paths to test.
- **Effort:** ~10 lines (file_picker) / ~120 lines (channel + Dart + fallback).

### 2️⃣ Keep the Photo Picker (status quo) — lowest risk, ignores the request
- **Pros:** deterministic system UI on every device; zero maintenance; already implemented and verified working; **on HyperOS 3/Android 16 this is literally the OEM-recommended API**; no "no handler" failure mode; no lost-result path beyond `ImageRecovery`, which already exists.
- **Cons:** the user sees "the picker, not my Gallery" and will keep complaining; flat list instead of albums.
- **Effort:** zero.
- **Choose this if** you cannot test the fallback on a non-Xiaomi device, or if product prefers consistency over OEM fidelity.

### 3️⃣ Show a chooser (`Intent.createChooser`) — most brand-neutral, worst taps
- **Pros:** Xiaomi Gallery is always visible as an option; works on every OEM; user stays in control.
- **Cons:** +1 tap on *every* pick; "Just once / Always" prompt noise; **the worst MIUI bug history** (Android 11 `RESULT_CANCELED`, CanHub #253); requires the MethodChannel anyway (no Flutter package exposes a chooser for `ACTION_PICK`).
- **Effort:** same as 2️⃣ plus chooser plumbing.

### Decision matrix

| | Opens Xiaomi Gallery | Google Photos risk | Extra taps | Permissions | Crop compat | Crash risk | Effort |
|---|---|---|---|---|---|---|---|
| **ACTION_PICK + fallback** | ✅ directly | ✅ none (GP doesn't handle PICK) | 0 | none | ✅ (cache copy) | low, if fallback exists | ~10 lines |
| **Photo Picker (now)** | ❌ | ✅ none | 0 | none | ✅ | very low | 0 |
| **Chooser** | ✅ as an option | ✅ user chooses | **+1 always** | none | ✅ (cache copy) | medium on MIUI 11/12 | medium |

### Concrete migration sketch (no code written — research only)

1. Run the Q1b `adb` commands on the user's phone. Confirm `PICK`/`image/*` resolves to `com.miui.gallery`; note the OS version (`ro.mi.os.version.name`) and whether `PICK_IMAGES` already resolves to a Xiaomi component.
2. If confirmed → `FilePicker.platform.pickFiles(type: FileType.image)` first, `ImagePicker().pickImage(...)` (Photo Picker) on `null`/`invalid_format_type`.
3. Keep `ImageRecovery` for the `image_picker` branch. For the `file_picker` branch, treat `null` as cancel — no recovery needed because `file_picker` completes synchronously per-call.
4. Move `maxWidth: 1600` from `pickImage(...)` to `ImageCropper().cropImage(maxWidth: 1600, ...)` so the size cap survives the switch.
5. Only if step 1 shows `PICK` resolving to something wrong → reconsider option 3️⃣ (chooser), not `setComponent`.

---

## Key Findings (TL;DR)

- **`ACTION_PICK` + `image/*` is the only intent that reliably lands in an OEM gallery**, and `file_picker` — already a dependency in this app — deliberately uses exactly that for `FileType.image` (verified in both 8.3.7 and 10.3.10 source).
- **Google Photos almost certainly does not register `ACTION_PICK`.** The "Google Photos steals my picker" problem is an `ACTION_GET_CONTENT` / `ACTION_VIEW` default-handler problem. Changing the action is therefore a targeted fix.
- **Do not hardcode `setComponent`.** The only publicly known component (`HomePageActivity`) is the launcher and will never return a pick result; the real picker activity name is undocumented and version-specific.
- **Xiaomi now officially recommends `MediaStore.ACTION_PICK_IMAGES`** for HyperOS 3 / Android 16+ (ITGSA alliance with OPPO/vivo/Honor). On older HyperOS that action is the Google MediaProvider picker — i.e. "the picker" the user dislikes is a transitional state, and the platform is not moving back toward `ACTION_PICK`.
- **`ACTION_PICK` has a real `ActivityNotFoundException` failure mode** on devices without a preinstalled gallery → any implementation needs a fallback, or it will crash for some users.
- **MIUI has two URI landmines:** `ACTION_PICK` returns an encoded MediaStore URI (not a path), and some builds return `RESULT_OK` with a **null** `Intent`/data. Always `ContentResolver.openInputStream`, always null-check.
- **`image_cropper` 8.1.0 needs `sourcePath: String`** — a `content://` URI cannot be passed. Copy to cache first (both `file_picker` and `image_picker` already do this for you).
- **`createChooser` on MIUI is risky**, not just noisy: MIUI 12/Android 11 returned `RESULT_CANCELED` (CanHub #253, pinned).

## Related Systems

- [`./android-gallery-vs-google-photos.md`](./android-gallery-vs-google-photos.md) — plugin-source truth for `image_picker_android` 0.8.13+17, `useAndroidPhotoPicker`, `maxWidth`, HEIC
- `image_cropper` 8.1.0 (uCrop) — `sourcePath`-only API
- `file_picker` 8.3.7 / 10.3.10 — `ACTION_PICK` for `FileType.image`
- Android Photo Picker (`MediaStore.ACTION_PICK_IMAGES`, `ActivityResultContracts.PickVisualMedia`, AOSP `PhotoPickerActivity`)
- Intent resolution, default handlers, package visibility (`<queries>`)

## Related Documentation

- [Xiaomi HyperOS dev — 照片视频选择控件](https://dev.mi.com/xiaomihyperos/documentation/detail?pId=2221) — official `ACTION_PICK_IMAGES` spec, HyperOS 3 / Android 16+, ITGSA-aligned
- [ITGSA (金标联盟) PhotoPicker guide](https://www.itgsa.com/doc/6631953378231296) — cross-OEM standard referenced by Xiaomi
- [AOSP MediaProvider — photopicker/README](https://android.googlesource.com/platform/packages/providers/MediaProvider/+/HEAD/photopicker/README) — `PICK_IMAGES` *and* `GET_CONTENT` route to PhotoPickerActivity; `pm query-activities` debugging
- [Android Photo Picker (official)](https://developer.android.com/training/data-storage/shared/photopicker)
- [CanHub/Android-Image-Cropper#253](https://github.com/CanHub/Android-Image-Cropper/issues/253) — MIUI + `createChooser` → `RESULT_CANCELED`
- [SO 67785661](https://stackoverflow.com/questions/67785661/taking-and-picking-photos-on-poco-x3-with-android-11-does-not-work) — same MIUI/Android 11 chooser failure
- [SO 32341573](https://stackoverflow.com/questions/32341573/how-to-pick-image-from-google-photos-app-only-android-google-photos-intent) — targeting Google Photos uses `GET_CONTENT` + package, not `PICK`
- [SO 66312517](https://stackoverflow.com/questions/66312517/no-activity-found-to-handle-intent-intent-action-pick) — `ACTION_PICK` `ActivityNotFoundException`
- [jrvansuita/PickImage#109](https://github.com/jrvansuita/PickImage/issues/109) — `act=android.intent.action.PICK typ=image/*` not handled on a device without a gallery
- [forum.diariumapp.com #4645](https://forum.diariumapp.com/d/4645-how-to-fix-the-button-add-file-to-open-file-manager-instead-of-gallery) — MIUI resolves file/photo picking straight to Xiaomi Gallery, no chooser
- [cnblogs — 解决小米手机上选择照片路径为null情况](https://www.cnblogs.com/manmanlu/p/6589151.html) — Xiaomi `ACTION_PICK` returns encoded URI; `isGooglePhotosUri` provider authority
- [MYSystemApp — com.miui.gallery](https://mysystemapp.com/packages/com.miui.gallery/) — package identity, Android 13–16, safe to disable (not a picker reference)

## Source files inspected (local, authoritative)

- `~/.pub-cache/hosted/pub.dev/file_picker-8.3.7/android/src/main/java/com/mr/flutter/plugin/filepicker/FilePickerDelegate.java:236-279` — `ACTION_PICK` for `image/*`, `resolveActivity` guard
- `~/.pub-cache/hosted/pub.dev/file_picker-8.3.7/android/src/main/java/com/mr/flutter/plugin/filepicker/FileUtils.java:257-303` — cache copy of `content://`
- `~/.pub-cache/hosted/pub.dev/file_picker-8.3.7/android/src/main/AndroidManifest.xml:3-8` — `<queries>` only for `GET_CONTENT`
- `~/.pub-cache/hosted/pub.dev/file_picker-10.3.10/android/src/main/kotlin/com/mr/flutter/plugin/filepicker/FileUtils.kt:140-201` — explicit "Use ACTION_PICK for images to allow using the Gallery app" comment
- `~/.pub-cache/hosted/pub.dev/file_picker-10.3.10/android/src/main/kotlin/com/mr/flutter/plugin/filepicker/FilePickerPlugin.kt:40` — `image` → `image/*`
- `~/.pub-cache/hosted/pub.dev/image_cropper-8.1.0/lib/src/cropper.dart:54-68` — `required String sourcePath`
- Repo: `beauty_shelf_app/lib/main.dart:17-23`, `lib/widgets/product_form.dart`, `pubspec.yaml:45-52`
