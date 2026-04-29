import 'dart:convert';
import 'package:http/http.dart' as http;
// ignore: avoid_web_libraries
import 'dart:html' as html;
import '../models/product.dart';

class ApiService {
  static const String baseUrl = '/api';

  Future<List<Product>> getProducts({String? type}) async {
    final uri = type != null
        ? Uri.parse('$baseUrl/products?type=$type')
        : Uri.parse('$baseUrl/products');

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }

  Future<List<Product>> searchProducts(String query) async {
    final uri = Uri.parse('$baseUrl/products/search/${Uri.encodeComponent(query)}');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Failed to search products');
    }
  }

  Future<Product> createProduct(Product product) async {
    final response = await http.post(
      Uri.parse('$baseUrl/products'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(product.toJson()),
    );

    if (response.statusCode == 200) {
      return Product.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create product');
    }
  }

  Future<Product> updateProduct(Product product) async {
    final response = await http.put(
      Uri.parse('$baseUrl/products/${product.id}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(product.toJson()),
    );

    if (response.statusCode == 200) {
      return Product.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update product');
    }
  }

  Future<void> deleteProduct(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/products/$id'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete product');
    }
  }

  Future<Map<String, dynamic>> lookupBarcode(String barcode) async {
    try {
      // Use backend as proxy to avoid CORS issues
      final response = await http.get(
        Uri.parse('$baseUrl/barcode/$barcode'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // If empty object returned, product not found
        if (data.isNotEmpty) {
          return data;
        }
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  // Export all products to JSON file
  Future<void> exportToJson(List<Product> products) async {
    final data = {
      'version': '1.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'products': products.map((p) => p.toJson()).toList(),
    };
    
    final jsonString = const JsonEncoder.withIndent('  ').convert(data);
    final bytes = utf8.encode(jsonString);
    final blob = html.Blob([bytes], 'application/json');
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'beauty_shelf_export_${DateTime.now().millisecondsSinceEpoch}.json')
      ..click();
    
    html.Url.revokeObjectUrl(url);
  }

  // Import products from JSON file
  Future<List<Product>?> importFromJson() async {
    final input = html.FileUploadInputElement()..accept = '.json';
    input.click();
    
    await input.onChange.first;
    
    if (input.files?.isNotEmpty == true) {
      final file = input.files!.first;
      final reader = html.FileReader();
      reader.readAsText(file);
      
      await reader.onLoadEnd.first;
      
      final content = reader.result as String;
      final data = json.decode(content) as Map<String, dynamic>;
      
      final productsList = data['products'] as List<dynamic>;
      return productsList.map((json) => Product.fromJson(json)).toList();
    }
    
    return null;
  }

  // Upload image and get URL
  Future<String?> uploadImage() async {
    final input = html.FileUploadInputElement()
      ..accept = 'image/*';
    input.click();
    
    await input.onChange.first;
    
    if (input.files?.isNotEmpty == true) {
      final file = input.files!.first;
      
      final formData = html.FormData();
      formData.appendBlob('file', file, file.name);
      
      try {
        final request = html.HttpRequest();
        request.open('POST', '$baseUrl/images/upload', async: false);
        request.send(formData);
        
        // Wait for completion (sync in dart:html)
        await request.onLoadEnd.first;
        
        if (request.status == 200) {
          final data = json.decode(request.responseText as String);
          return data['url'] as String?;
        }
      } catch (e) {
        // Fallback - try with http package
      }
    }
    
    return null;
  }
}
