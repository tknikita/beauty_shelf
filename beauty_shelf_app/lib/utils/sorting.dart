import '../models/product.dart';

enum SortField { name, expiry, category, position }

enum SortOrder { asc, desc }

/// Sorts a list of products by the given field and order.
List<Product> sortProducts(
  List<Product> products,
  SortField field,
  SortOrder order,
) {
  final sorted = List<Product>.from(products);
  sorted.sort((a, b) {
    int cmp;
    switch (field) {
      case SortField.name:
        cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        break;
      case SortField.expiry:
        cmp = a.daysLeft.compareTo(b.daysLeft);
        break;
      case SortField.category:
        final catA = Categories.getCategoryName(a.type, a.category).toLowerCase();
        final catB = Categories.getCategoryName(b.type, b.category).toLowerCase();
        cmp = catA.compareTo(catB);
        break;
      case SortField.position:
        cmp = a.position.compareTo(b.position);
        break;
    }
    return order == SortOrder.asc ? cmp : -cmp;
  });
  return sorted;
}