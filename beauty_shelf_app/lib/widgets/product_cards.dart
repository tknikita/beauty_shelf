import 'package:flutter/material.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';
import 'product_card.dart';

class ProductCards extends StatelessWidget {
  final List<Product> products;
  final Function(Product) onEdit;
  final Function(Product) onDelete;

  const ProductCards({
    super.key,
    required this.products,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.instance;

    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: theme.textLightColor),
            const SizedBox(height: 16),
            Text(
              'Нет продуктов',
              style: TextStyle(fontSize: 18, color: theme.textLightColor),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        ...products.map((p) => ProductCard(
          product: p,
          onEdit: () => onEdit(p),
          onDelete: () => onDelete(p),
        )),
        const SizedBox(height: 96), // Space for FAB
      ],
    );
  }
}
