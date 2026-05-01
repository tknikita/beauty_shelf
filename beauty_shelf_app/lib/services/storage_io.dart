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
    final db = await database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
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
}
