import 'dart:convert';
import 'dart:io';
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
      version: 2,
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
    final id = await db.insert('products', map);
    return product.copyWith(id: id);
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

    // Query products expiring within `days` days, considering:
    // 1. Original expiry_date
    // 2. Opened products: opened_date + expiry_days_after_open
    final maps = await db.rawQuery('''
      SELECT * FROM products 
      WHERE expiry_date <= ?
         OR (is_opened = 1 AND opened_date IS NOT NULL 
             AND date(opened_date, '+' || expiry_days_after_open || ' days') <= ?)
      ORDER BY expiry_date ASC
    ''', [thresholdStr, thresholdStr]);
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  @override
  Future<String?> exportToJson() async {
    try {
      final products = await getAllProducts();
      final data = {
        'version': '1.0',
        'exportedAt': DateTime.now().toIso8601String(),
        'products': products.map((p) => p.toJson()).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = path.join(dir.path, 'beauty_shelf_export_$timestamp.json');

      final file = File(filePath);
      await file.writeAsString(jsonString);

      return filePath;
    } catch (e) {
      print('Export error: $e');
      return null;
    }
  }

  @override
  Future<int> importFromJson(String content) async {
    try {
      final data = json.decode(content) as Map<String, dynamic>;
      final productsList = data['products'] as List<dynamic>;
      int count = 0;

      for (final jsonProduct in productsList) {
        final product = Product.fromJson(jsonProduct);
        await createProduct(product.copyWith(id: null));
        count++;
      }
      return count;
    } catch (e) {
      print('Import error: $e');
      return 0;
    }
  }

  /// Write image bytes to app's local storage and return the local path.
  @override
  Future<String?> saveImageBytes(List<int> bytes, String? fileName) async {
    try {
      if (bytes.length > _maxImageSize) {
        print('Image rejected: ${bytes.length} bytes exceeds $_maxImageSize');
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
      print('Error saving image: $e');
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
      print('Error deleting image: $e');
    }
  }

  bool _isLocalPath(String path) => Product.isLocalPath(path);
}
