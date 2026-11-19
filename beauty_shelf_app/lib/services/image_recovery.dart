import 'package:image_picker/image_picker.dart';

/// Recovers a photo the operating system swallowed while the camera or the
/// picker was in the foreground.
///
/// Android may destroy the hosting activity (and, on low memory, the whole
/// process) while an external camera/picker activity is on top. When that
/// happens the selected file is never delivered to the awaiting call — the
/// plugin parks it instead. `ImagePicker.retrieveLostData()` hands it back,
/// but only to whoever asks, and only once.
///
/// The app restarts on the home screen after process death, so [ProductForm]
/// does not exist yet at that moment. This small app-level stash parks the
/// recovered file until a form is opened and can consume it.
class ImageRecovery {
  ImageRecovery._();

  static final ImageRecovery instance = ImageRecovery._();

  final ImagePicker _picker = ImagePicker();

  XFile? _pending;
  bool _checking = false;

  /// Asks the plugin for interrupted selections and stashes the first one.
  ///
  /// Safe to call repeatedly: the plugin does not redeliver the same payload,
  /// and an already stashed file is kept rather than replaced.
  Future<void> check() async {
    if (_checking) return;
    _checking = true;
    try {
      final response = await _picker.retrieveLostData();
      if (response.isEmpty || response.type != RetrieveType.image) return;

      final recovered = response.file ?? _firstOf(response.files);
      if (recovered == null) return;

      _pending ??= recovered;
    } catch (_) {
      // Recovery is best-effort: never let it break app startup.
    } finally {
      _checking = false;
    }
  }

  static XFile? _firstOf(List<XFile>? files) {
    if (files == null || files.isEmpty) return null;
    return files.first;
  }

  /// Returns the stashed file once and clears it, so the flow runs at most
  /// once per interrupted selection.
  XFile? take() {
    final file = _pending;
    _pending = null;
    return file;
  }
}
