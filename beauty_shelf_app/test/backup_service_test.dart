import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polochka/models/product.dart';
import 'package:polochka/services/backup_service.dart';
import 'package:polochka/services/storage_service.dart';
import 'package:polochka/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-memory StorageService so the backup round-trip can run without a device.
class _FakeStorage implements StorageService {
  final List<Product> _products = [];
  final Map<String, List<int>> savedImages = {};
  int _nextId = 1;

  @override
  Future<List<Product>> getAllProducts() async => List.of(_products);

  @override
  Future<List<Product>> getProductsByType(String type) async =>
      _products.where((p) => p.type == type).toList();

  @override
  Future<Product> createProduct(Product product) async {
    final stored = product.copyWith(id: _nextId++);
    _products.add(stored);
    return stored;
  }

  @override
  Future<void> updateProduct(Product product) async {
    final i = _products.indexWhere((p) => p.id == product.id);
    if (i >= 0) _products[i] = product;
  }

  @override
  Future<void> deleteProduct(int id) async {
    _products.removeWhere((p) => p.id == id);
  }

  @override
  Future<List<Product>> searchProducts(String query) async => List.of(_products);

  @override
  Future<List<Product>> getExpiringProducts(int days) async => List.of(_products);

  @override
  Future<String?> saveImageBytes(List<int> bytes, String? fileName) async {
    final name = fileName ?? 'image.jpg';
    final path = '/tmp/restored_$name';
    savedImages[path] = bytes;
    return path;
  }

  @override
  Future<void> deleteImage(String? imagePath) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppTheme.instance.resetCategoriesForTest();
  });

  test('backup round-trip restores products, images and app state', () async {
    final tmp = await Directory.systemTemp.createTemp('bs_backup_test');
    final img = File('${tmp.path}/product_1.jpg')..writeAsBytesSync([1, 2, 3, 4, 5]);

    final storage = _FakeStorage();
    await storage.createProduct(Product(
      name: 'Крем',
      type: 'care',
      category: 'cream',
      expiryDate: DateTime(2027, 1, 1),
      imageUrl: img.path,
    ));

    AppTheme.instance.addGroup('care', 'gX', 'Мой раздел');
    AppTheme.instance.applyPreset(
      const Color(0xFFA7E8C4),
      const Color(0xFFF3FAF5),
    );

    final service = BackupService(storage: storage);
    final bytes = await service.buildArchive();
    expect(bytes, isNotNull);

    // Wipe products + state, then restore.
    for (final p in await storage.getAllProducts()) {
      await storage.deleteProduct(p.id!);
    }
    AppTheme.instance.resetCategoriesForTest();
    AppTheme.instance.applyPreset(
      const Color(0xFFE8B4BC),
      const Color(0xFFFDF9FA),
    );

    final count = await service.restoreFromZipBytes(Uint8List.fromList(bytes!));
    expect(count, 1);

    final restored = await storage.getAllProducts();
    expect(restored, hasLength(1));
    expect(restored.first.name, 'Крем');
    expect(restored.first.category, 'cream');
    expect(restored.first.imageUrl, contains('product_1.jpg'));
    expect(storage.savedImages['/tmp/restored_product_1.jpg'], isNotNull);

    expect(AppTheme.instance.getGroupsByType('care')['gX'], 'Мой раздел');
    expect(AppTheme.instance.backgroundColor.toARGB32(), 0xFFF3FAF5);

    await tmp.delete(recursive: true);
  });

  test('restoring a non-backup zip throws', () async {
    final archive = Archive();
    final data = utf8.encode('{"app":"other"}');
    archive.addFile(ArchiveFile('backup.json', data.length, data));
    final bytes = Uint8List.fromList(ZipEncoder().encode(archive)!);

    final service = BackupService(storage: _FakeStorage());
    expect(
      () => service.restoreFromZipBytes(bytes),
      throwsA(isA<Exception>()),
    );
  });
}
