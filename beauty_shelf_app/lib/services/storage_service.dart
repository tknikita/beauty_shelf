import '../models/product.dart';

// Abstract storage interface
abstract class StorageService {
  Future<List<Product>> getAllProducts();
  Future<List<Product>> getProductsByType(String type);
  Future<Product> createProduct(Product product);
  Future<void> updateProduct(Product product);
  Future<void> deleteProduct(int id);
  Future<List<Product>> searchProducts(String query);
  Future<List<Product>> getExpiringProducts(int days);
  Future<String?> exportToJson();
  Future<int> importFromJson(String content);
  
  // Image management
  // Mobile/desktop: writes bytes to local storage, returns local path.
  // Web: uploads bytes to the backend, returns the served URL.
  Future<String?> saveImageBytes(List<int> bytes, String? fileName);
  Future<void> deleteImage(String? imagePath);
}
