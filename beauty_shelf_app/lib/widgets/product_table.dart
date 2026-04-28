import 'package:flutter/material.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';

class ProductTable extends StatelessWidget {
  final List<Product> products;
  final Function(Product) onEdit;
  final Function(Product) onDelete;

  const ProductTable({
    super.key,
    required this.products,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Название | Тип | Срок', style: TextStyle(fontWeight: FontWeight.bold)),
        ...products.map((p) => Text('${p.name} | ${p.type} | ${p.effectiveExpiryDate}')),
      ],
    );
  }
}
