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
  static const int _maxImageSize = 500 * 1024; // 500KB

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final dbFile = path.join(dbPath, 'beauty_shelf.db');

    return await openDatabase(
      dbFile,
      version: 1,
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
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            updated_at TEXT DEFAULT CURRENT_TIMESTAMP
          )
        ''');
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

    final maps = await db.query(
      'products',
      where: 'expiry_date <= ?',
      whereArgs: [thresholdStr],
      orderBy: 'expiry_date ASC',
    );
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

  /// Copy image to app's local storage and return local path
  @override
  Future<String?> saveImage(String sourcePath) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final imagesPath = path.join(dir.path, _imagesDir);
      
      // Create images directory if not exists
      final imagesDir = Directory(imagesPath);
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ext = path.extension(sourcePath).toLowerCase();
      final validExt = ['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(ext) ? ext : '.jpg';
      final localFileName = 'product_$timestamp$validExt';
      final localPath = path.join(imagesPath, localFileName);

      // Copy file
      final sourceFile = File(sourcePath);
      await sourceFile.copy(localPath);

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

  bool _isLocalPath(String path) {
    return path.startsWith('/data/') ||
           path.startsWith('/storage/') ||
           path.startsWith('data/');
  }
}
