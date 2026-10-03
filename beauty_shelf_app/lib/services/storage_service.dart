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

  // Image management
  // Writes bytes to local storage and returns the local path.
  Future<String?> saveImageBytes(List<int> bytes, String? fileName);
  Future<void> deleteImage(String? imagePath);
}
