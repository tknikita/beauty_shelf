import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import '../models/product.dart';
import '../theme/app_theme.dart';
import 'storage_factory.dart';
import 'storage_service.dart';

/// Local (device) backup: a single `.zip` containing the product database,
/// the full app state (theme + categories) and every locally stored image.
///
/// The file is written wherever the user picks through the system save dialog
/// (Downloads, a cloud-synced folder, etc.), so it survives app uninstall.
class BackupService {
  BackupService({StorageService? storage})
      : _storage = storage ?? createStorageService();

  final StorageService _storage;

  static const _manifest = 'backup.json';
  static const _imagesDir = 'images';
  static const _formatVersion = 1;
  static const appTag = 'beauty_shelf';

  /// Builds the zip payload (products + app state + images).
  @visibleForTesting
  Future<Uint8List?> buildArchive() async {
    try {
      final products = await _storage.getAllProducts();
      final archive = Archive();

      final manifest = jsonEncode({
        'format': _formatVersion,
        'app': appTag,
        'exportedAt': DateTime.now().toIso8601String(),
        'products': products.map((p) => p.toJson()).toList(),
        'state': AppTheme.instance.toBackup(),
      });
      final manifestBytes = utf8.encode(manifest);
      archive.addFile(ArchiveFile(_manifest, manifestBytes.length, manifestBytes));

      // Bundle every locally stored image referenced by a product.
      final added = <String>{};
      for (final product in products) {
        final url = product.imageUrl;
        if (url == null || !Product.isLocalPath(url)) continue;
        final name = path.basename(url);
        if (!added.add(name)) continue;
        final file = File(url);
        if (!await file.exists()) continue;
        final bytes = await file.readAsBytes();
        archive.addFile(ArchiveFile('$_imagesDir/$name', bytes.length, bytes));
      }

      final zip = ZipEncoder().encode(archive);
      if (zip == null) return null;
      return Uint8List.fromList(zip);
    } catch (e) {
      debugPrint('buildArchive error: $e');
      return null;
    }
  }

  /// Builds a zip backup and asks the user where to save it.
  ///
  /// Returns the saved path, or `null` when the user cancels / on failure.
  Future<String?> exportBackup() async {
    final bytes = await buildArchive();
    if (bytes == null) return null;

    return FilePicker.platform.saveFile(
      dialogTitle: 'Сохранить резервную копию',
      fileName: 'beauty_shelf_backup_${_timestamp()}.zip',
      bytes: bytes,
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
  }

  /// Restores a zip payload, **replacing** all current data.
  ///
  /// Returns the number of restored products.
  @visibleForTesting
  Future<int> restoreFromZipBytes(Uint8List bytes) async {
    final archive = ZipDecoder().decodeBytes(bytes);
    ArchiveFile? manifestFile;
    for (final f in archive.files) {
      if (f.name == _manifest) {
        manifestFile = f;
        break;
      }
    }
    if (manifestFile == null) {
      throw Exception('Это не резервная копия Полочки');
    }

    final manifest =
        jsonDecode(utf8.decode(manifestFile.content as List<int>)) as Map<String, dynamic>;
    if (manifest['app'] != appTag) {
      throw Exception('Неизвестный формат резервной копии');
    }

    final productMaps = (manifest['products'] as List?) ?? const [];
    final state = (manifest['state'] as Map?)?.cast<String, dynamic>();

    final images = <String, ArchiveFile>{};
    for (final f in archive.files) {
      if (f.name.startsWith('$_imagesDir/')) {
        images[path.basename(f.name)] = f;
      }
    }

    // Replace semantics: clear existing products first.
    for (final p in await _storage.getAllProducts()) {
      if (p.id != null) await _storage.deleteProduct(p.id!);
    }

    var count = 0;
    for (final raw in productMaps) {
      final map = (raw as Map).cast<String, dynamic>();
      var product = Product.fromJson(map);
      final url = product.imageUrl;

      if (url != null && Product.isLocalPath(url)) {
        final archived = images[path.basename(url)];
        String? newPath;
        if (archived != null) {
          newPath = await _storage.saveImageBytes(
            archived.content as List<int>,
            path.basename(url),
          );
        }
        product = product.copyWith(
          id: null,
          imageUrl: newPath,
          clearImageUrl: newPath == null,
        );
      } else {
        product = product.copyWith(id: null);
      }

      await _storage.createProduct(product);
      count++;
    }

    if (state != null) AppTheme.instance.applyBackup(state);

    return count;
  }

  /// Picks a backup zip and restores it. Returns the restored product count,
  /// or `-1` when the user cancels.
  Future<int> restoreBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return -1;

    final bytes = result.files.single.bytes;
    if (bytes == null) throw Exception('Не удалось прочитать файл');

    return restoreFromZipBytes(bytes);
  }

  String _timestamp() {
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${now.year}-${two(now.month)}-${two(now.day)}'
        '_${two(now.hour)}${two(now.minute)}';
  }
}
