import 'package:flutter/material.dart';
import '../models/product.dart';

enum SortField { name, expiry, category }

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
    }
    return order == SortOrder.asc ? cmp : -cmp;
  });
  return sorted;
}

/// Returns the appropriate icon for a sort field.
IconData getSortIcon(SortField currentField, SortField targetField, SortOrder order) {
  if (currentField != targetField) return Icons.unfold_more;
  return order == SortOrder.asc ? Icons.arrow_upward : Icons.arrow_downward;
}