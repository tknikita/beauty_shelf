import 'dart:convert';
import 'dart:typed_data';
// ignore: avoid_web_libraries
import 'dart:html' as html;
import 'package:http/http.dart' as http;
import 'storage_service.dart';
import '../models/product.dart';

StorageService createStorage() => WebStorageService();

class WebStorageService implements StorageService {
  static const String _baseUrl = '/api';

  @override
  Future<List<Product>> getAllProducts() async {
    final response = await http.get(Uri.parse('$_baseUrl/products'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Product.fromJson(json)).toList();
    }
    throw Exception('Failed to load products');
  }

  @override
  Future<List<Product>> getProductsByType(String type) async {
    final response = await http.get(Uri.parse('$_baseUrl/products?type=$type'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Product.fromJson(json)).toList();
    }
    throw Exception('Failed to load products');
  }

  @override
  Future<Product> createProduct(Product product) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/products'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(product.toJson()),
    );
    // Backend responds with 201 Created.
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Product.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to create product (${response.statusCode})');
  }

  @override
  Future<void> updateProduct(Product product) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/products/${product.id}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(product.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update product');
    }
  }

  @override
  Future<void> deleteProduct(int id) async {
    final response = await http.delete(Uri.parse('$_baseUrl/products/$id'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete product');
    }
  }

  @override
  Future<List<Product>> searchProducts(String query) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/products/search/${Uri.encodeComponent(query)}'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Product.fromJson(json)).toList();
    }
    throw Exception('Failed to search products');
  }

  @override
  Future<List<Product>> getExpiringProducts(int days) async {
    final response = await http.get(Uri.parse('$_baseUrl/expiring?days=$days'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Product.fromJson(json)).toList();
    }
    throw Exception('Failed to get expiring products');
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
      final bytes = utf8.encode(jsonString);
      final blob = html.Blob([bytes], 'application/json');
      final url = html.Url.createObjectUrlFromBlob(blob);

      html.AnchorElement(href: url)
        ..setAttribute('download', 'beauty_shelf_export_${DateTime.now().millisecondsSinceEpoch}.json')
        ..click();

      html.Url.revokeObjectUrl(url);
      return 'Downloaded';
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

  // Web uses remote URLs - local image operations are no-ops
  @override
  Future<String?> saveImage(String sourcePath) async => null;

  @override
  Future<void> deleteImage(String? imagePath) async {}
}
