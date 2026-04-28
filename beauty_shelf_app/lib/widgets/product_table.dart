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

  Color _getStatusColor(Product p) {
    switch (p.status) {
      case ProductStatus.ok:
        return AppTheme.instance.okColor;
      case ProductStatus.warning:
        return AppTheme.instance.warningColor;
      case ProductStatus.danger:
      case ProductStatus.expired:
        return AppTheme.instance.dangerColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.instance;
    
    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Нет продуктов',
            style: TextStyle(color: theme.textLightColor),
          ),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final p = products[index];
        return _TableRow(
          product: p,
          statusColor: _getStatusColor(p),
          onEdit: () => onEdit(p),
          onDelete: () => onDelete(p),
        );
      },
    );
  }
}

class _TableRow extends StatelessWidget {
  final Product product;
  final Color statusColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TableRow({
    required this.product,
    required this.statusColor,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.instance;
    final daysText = product.daysLeft < 0 
        ? 'Просрочено ${-product.daysLeft} дн.'
        : product.daysLeft == 0 
            ? 'Истекает сегодня' 
            : '${product.daysLeft} дн.';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: theme.surfaceColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.borderColor),
        ),
        child: Row(
          children: [
            // Image or icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: theme.primaryColor.withAlpha(25),
                borderRadius: BorderRadius.circular(6),
              ),
              child: product.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        product.imageUrl!.startsWith('/') 
                            ? '/api${product.imageUrl}' 
                            : product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.inventory_2_outlined,
                          size: 18,
                          color: theme.primaryColor,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.inventory_2_outlined,
                      size: 18,
                      color: theme.primaryColor,
                    ),
            ),
            const SizedBox(width: 10),
            // Name & category
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: theme.textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    Categories.getCategoryName(product.type, product.category),
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.textLightColor,
                    ),
                  ),
                ],
              ),
            ),
            // Type badge
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: product.type == 'care' 
                      ? Colors.blue.withAlpha(25) 
                      : Colors.purple.withAlpha(25),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  product.type == 'care' ? 'Уход' : 'Декор',
                  style: TextStyle(
                    fontSize: 10,
                    color: product.type == 'care' ? Colors.blue : Colors.purple,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Status
            Expanded(
              flex: 1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      daysText,
                      style: TextStyle(
                        fontSize: 11,
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: onEdit,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.edit_outlined, size: 16, color: theme.textLightColor),
                  ),
                ),
                InkWell(
                  onTap: onDelete,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.delete_outline, size: 16, color: theme.dangerColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
