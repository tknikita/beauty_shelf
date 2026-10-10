import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service for external API calls (barcode lookup, etc.)
class ApiService {
  // Data sources (ordered by relevance for cosmetics)
  static const List<_ApiSource> _sources = [
    _ApiSource(
      name: 'Open Beauty Facts',
      baseUrl: 'https://world.openbeautyfacts.org/api/v2/product',
      productKey: 'product_name',
      brandKey: 'brands',
    ),
    _ApiSource(
      name: 'Open Food Facts', 
      baseUrl: 'https://world.openfoodfacts.org/api/v2/product',
      productKey: 'product_name',
      brandKey: 'brands',
    ),
    _ApiSource(
      name: 'Open Beauty Facts (fr)',
      baseUrl: 'https://fr.openbeautyfacts.org/api/v2/product',
      productKey: 'product_name',
      brandKey: 'brands',
    ),
    _ApiSource(
      name: 'Open Food Facts (com)',
      baseUrl: 'https://com.openfoodfacts.org/api/v2/product',
      productKey: 'product_name',
      brandKey: 'brands',
    ),
  ];
  
  /// Lookup product by barcode using multiple sources
  static Future<Map<String, dynamic>?> lookupBarcode(String barcode) async {
    for (final source in _sources) {
      final result = await _lookupFromApi(barcode, source);
      if (result != null) {
        debugPrint('Found in: ${source.name}');
        return result;
      }
    }
    
    // Try search API as fallback
    return _searchByBarcode(barcode);
  }
  
  static Future<Map<String, dynamic>?> _lookupFromApi(
    String barcode, 
    _ApiSource source,
  ) async {
    try {
      final url = '${source.baseUrl}/$barcode.json';
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'BeautyShelf/1.0 (Android)'},
      ).timeout(const Duration(seconds: 8));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['status'] == 1) {
          final product = data['product'] as Map<String, dynamic>?;
          if (product != null) {
            // Extract usable fields
            final name = product[source.productKey] ?? 
                         product['product_name'] ?? 
                         product['name'];
            final brand = product[source.brandKey] ?? 
                          product['brand'] ?? 
                          product['brands'];
            
            return {
              'name': name,
              'brand': brand,
              'barcode': barcode,
              'image_url': product['image_url'] ?? product['image_front_url'],
              'category': product['categories'] ?? product['category'],
              'source': source.name,
            };
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('${source.name} error: $e');
      return null;
    }
  }
  
  /// Search using the search endpoint
  static Future<Map<String, dynamic>?> _searchByBarcode(String barcode) async {
    try {
      // Open Food Facts search
      final url = 'https://world.openfoodfacts.org/cgi/search.pl'
          '?search_terms=$barcode'
          '&search_simple=1'
          '&action=process'
          '&json=1';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'BeautyShelf/1.0 (Android)'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final products = data['products'] as List<dynamic>?;
        
        if (products != null && products.isNotEmpty) {
          final product = products.first as Map<String, dynamic>;
          return {
            'name': product['product_name'] ?? product['product_name_en'],
            'brand': product['brands'],
            'barcode': barcode,
            'image_url': product['image_front_url'],
            'category': product['categories'],
            'source': 'search',
          };
        }
      }
      return null;
    } catch (e) {
      debugPrint('Search error: $e');
      return null;
    }
  }
}

class _ApiSource {
  final String name;
  final String baseUrl;
  final String productKey;
  final String brandKey;
  
  const _ApiSource({
    required this.name,
    required this.baseUrl,
    required this.productKey,
    required this.brandKey,
  });
}
