import 'package:flutter/material.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';
import 'product_card.dart';

enum SortField { name, expiry, category }
enum SortOrder { asc, desc }

class ProductCards extends StatefulWidget {
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
  State<ProductCards> createState() => _ProductCardsState();
}

class _ProductCardsState extends State<ProductCards> {
  SortField _sortField = SortField.expiry;
  SortOrder _sortOrder = SortOrder.asc;

  List<Product> get _sortedProducts {
    final sorted = List<Product>.from(widget.products);
    sorted.sort((a, b) {
      int cmp;
      switch (_sortField) {
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
      return _sortOrder == SortOrder.asc ? cmp : -cmp;
    });
    return sorted;
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
    if (_sortField != field) return Icons.unfold_more;
    return _sortOrder == SortOrder.asc ? Icons.arrow_upward : Icons.arrow_downward;
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.instance;
    final products = _sortedProducts;
    
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
        // Sort bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: theme.surfaceColor,
            border: Border(bottom: BorderSide(color: theme.borderColor)),
          ),
          child: Row(
            children: [
              _SortChip(
                label: 'По сроку',
                icon: _getSortIcon(SortField.expiry),
                isActive: _sortField == SortField.expiry,
                onTap: () => _toggleSort(SortField.expiry),
              ),
              const SizedBox(width: 8),
              _SortChip(
                label: 'По названию',
                icon: _getSortIcon(SortField.name),
                isActive: _sortField == SortField.name,
                onTap: () => _toggleSort(SortField.name),
              ),
              const SizedBox(width: 8),
              _SortChip(
                label: 'По категории',
                icon: _getSortIcon(SortField.category),
                isActive: _sortField == SortField.category,
                onTap: () => _toggleSort(SortField.category),
              ),
            ],
          ),
        ),
        // Cards grid - no separate scrolling, parent handles it
        LayoutBuilder(
          builder: (context, constraints) {
            // Adaptive: 2 columns on mobile, more on tablet/desktop
            final width = constraints.maxWidth;
            final crossAxisCount = width > 600 ? (width > 900 ? 3 : 2) : 2;
            final itemWidth = (width - 24 - (crossAxisCount - 1) * 8) / crossAxisCount;
            
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: itemWidth / 130,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final p = products[index];
                return ProductCard(
                  product: p,
                  onEdit: () => widget.onEdit(p),
                  onDelete: () => widget.onDelete(p),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.instance;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? theme.primaryColor.withAlpha(25) : theme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? theme.primaryColor : theme.borderColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? theme.primaryColor : theme.textColor,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              icon,
              size: 14,
              color: isActive ? theme.primaryColor : theme.textLightColor,
            ),
          ],
        ),
      ),
    );
  }
}
