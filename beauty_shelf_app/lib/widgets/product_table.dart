import 'package:flutter/material.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';
import '../utils/sorting.dart';

class ProductTable extends StatefulWidget {
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
  State<ProductTable> createState() => _ProductTableState();
}

class _ProductTableState extends State<ProductTable> {
  SortField _sortField = SortField.expiry;
  SortOrder _sortOrder = SortOrder.asc;

  List<Product> get _sortedProducts {
    return sortProducts(widget.products, _sortField, _sortOrder);
  }

  void _toggleSort(SortField field) {
    setState(() {
      if (_sortField == field) {
        _sortOrder = _sortOrder == SortOrder.asc ? SortOrder.desc : SortOrder.asc;
      } else {
        _sortField = field;
        _sortOrder = SortOrder.asc;
      }
    });
  }

  IconData _getSortIcon(SortField field) {
    return getSortIcon(_sortField, field, _sortOrder);
  }

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
    final products = _sortedProducts;
    
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
    
    return Column(
      children: [
        // Sort header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.surfaceColor,
            border: Border(bottom: BorderSide(color: theme.borderColor)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 46), // Image space
              Expanded(
                flex: 3,
                child: _SortButton(
                  label: 'Название',
                  icon: _getSortIcon(SortField.name),
                  onTap: () => _toggleSort(SortField.name),
                  isActive: _sortField == SortField.name,
                ),
              ),
              Expanded(
                flex: 2,
                child: _SortButton(
                  label: 'Категория',
                  icon: _getSortIcon(SortField.category),
                  onTap: () => _toggleSort(SortField.category),
                  isActive: _sortField == SortField.category,
                ),
              ),
              SizedBox(
                width: 60,
                child: Text(
                  'Тип',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: theme.textLightColor),
                ),
              ),
              Expanded(
                flex: 1,
                child: _SortButton(
                  label: 'Срок',
                  icon: _getSortIcon(SortField.expiry),
                  onTap: () => _toggleSort(SortField.expiry),
                  isActive: _sortField == SortField.expiry,
                ),
              ),
              const SizedBox(width: 50), // Actions space
            ],
          ),
        ),
        // Product list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final p = products[index];
              return _TableRow(
                product: p,
                statusColor: _getStatusColor(p),
                onEdit: () => widget.onEdit(p),
                onDelete: () => widget.onDelete(p),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SortButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  const _SortButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.instance;
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? theme.primaryColor : theme.textLightColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 2),
          Icon(icon, size: 14, color: isActive ? theme.primaryColor : theme.textLightColor),
        ],
      ),
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
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: theme.surfaceColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.borderColor),
        ),
        child: Row(
          children: [
            // Image or icon with opened indicator
            Stack(
              children: [
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
                if (product.isOpened)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: theme.warningColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.open_in_new,
                        size: 8,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            // Name
            Expanded(
              flex: 3,
              child: Text(
                product.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: theme.textColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Category
            Expanded(
              flex: 2,
              child: Text(
                Categories.getCategoryName(product.type, product.category),
                style: TextStyle(
                  fontSize: 11,
                  color: theme.textLightColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Type badge
            SizedBox(
              width: 60,
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
