import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'storage_service.dart';
import '../models/product.dart';

StorageService createStorage() => MobileStorageService();

class MobileStorageService implements StorageService {
  Database? _database;
  static const String _imagesDir = 'images';
  static const int _maxImageSize = 5 * 1024 * 1024; // 5 MB

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final dbFile = path.join(dbPath, 'beauty_shelf.db');

    return await openDatabase(
      dbFile,
      version: 4,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            category TEXT NOT NULL,
            purpose TEXT,
            expiry_date TEXT NOT NULL,
            is_opened INTEGER DEFAULT 0,
            opened_date TEXT,
            expiry_days_after_open INTEGER DEFAULT 30,
            image_url TEXT,
            notification_days INTEGER,
            quantity INTEGER DEFAULT 1,
            brand TEXT,
            position INTEGER DEFAULT 0,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            updated_at TEXT DEFAULT CURRENT_TIMESTAMP
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE products ADD COLUMN notification_days INTEGER',
          );
        }
        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE products ADD COLUMN quantity INTEGER DEFAULT 1',
          );
        }
        if (oldVersion < 4) {
          await db.execute('ALTER TABLE products ADD COLUMN brand TEXT');
          await db.execute(
            'ALTER TABLE products ADD COLUMN position INTEGER DEFAULT 0',
          );
          // Give existing rows a stable manual order.
          await db.execute('UPDATE products SET position = id');
        }
      },
    );
  }

  @override
  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final maps = await db.query('products', orderBy: 'expiry_date ASC');
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  @override
  Future<List<Product>> getProductsByType(String type) async {
    final db = await database;
    final maps = await db.query(
      'products',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'expiry_date ASC',
    );
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  @override
  Future<Product> createProduct(Product product) async {
    final db = await database;
    final map = product.toMap()..remove('id');
    // Append new products to the end of the manual order.
    if ((map['position'] as int?) == null || (map['position'] as int) == 0) {
      final r = await db.rawQuery(
        'SELECT COALESCE(MAX(position), 0) + 1 AS next FROM products',
      );
      map['position'] = (r.first['next'] as int?) ?? 1;
    }
    final id = await db.insert('products', map);
    return product.copyWith(id: id, position: map['position'] as int);
  }

  @override
  Future<void> updateProduct(Product product) async {
    final db = await database;
    await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  @override
  Future<void> deleteProduct(int id) async {
    // Fetch product to get image path before deletion
    final product = await getProductById(id);
    
    // Delete image if exists
    if (product?.imageUrl != null) {
      await deleteImage(product!.imageUrl);
    }
    
    final db = await database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }
  
  Future<Product?> getProductById(int id) async {
    final db = await database;
    final maps = await db.query('products', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Product.fromMap(maps.first);
  }

  @override
  Future<List<Product>> searchProducts(String query) async {
    final db = await database;
    final maps = await db.query(
      'products',
      where: 'name LIKE ? OR purpose LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  @override
  Future<List<Product>> getExpiringProducts(int days) async {
    final db = await database;
    final now = DateTime.now();
    final threshold = now.add(Duration(days: days));
    final thresholdStr = threshold.toIso8601String().split('T')[0];

    // Effective expiry is the earlier of the printed expiry_date and the PAO
    // limit (opened_date + expiry_days_after_open), matching
    // Product.effectiveExpiryDate. The threshold is a local date string so it
    // matches Product.daysLeft.
    final maps = await db.rawQuery('''
      SELECT * FROM products
      WHERE MIN(
        expiry_date,
        CASE
          WHEN is_opened = 1 AND opened_date IS NOT NULL
            THEN date(opened_date, '+' || expiry_days_after_open || ' days')
          ELSE expiry_date
        END
      ) <= ?
      ORDER BY expiry_date ASC
    ''', [thresholdStr]);
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  /// Write image bytes to app's local storage and return the local path.
  @override
  Future<String?> saveImageBytes(List<int> bytes, String? fileName) async {
    try {
      if (bytes.length > _maxImageSize) {
        debugPrint('Image rejected: ${bytes.length} bytes exceeds $_maxImageSize');
        return null;
      }

      final dir = await getApplicationDocumentsDirectory();
      final imagesPath = path.join(dir.path, _imagesDir);

      // Create images directory if not exists
      final imagesDir = Directory(imagesPath);
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      // Generate unique filename, preserving a valid extension
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ext = path.extension(fileName ?? '').toLowerCase();
      final validExt = ['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(ext) ? ext : '.jpg';
      final localPath = path.join(imagesPath, 'product_$timestamp$validExt');

      await File(localPath).writeAsBytes(bytes, flush: true);

      return localPath;
    } catch (e) {
      debugPrint('Error saving image: $e');
      return null;
    }
  }

  /// Delete image from local storage
  @override
  Future<void> deleteImage(String? imagePath) async {
    if (imagePath == null || !_isLocalPath(imagePath)) return;
    
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting image: $e');
    }
  }

  bool _isLocalPath(String path) => Product.isLocalPath(path);
}
