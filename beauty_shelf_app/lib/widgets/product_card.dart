import 'package:flutter/material.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProductCard({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  Color _getStatusColor() {
    switch (product.status) {
      case ProductStatus.ok:
        return AppTheme.instance.okColor;
      case ProductStatus.warning:
        return AppTheme.instance.warningColor;
      case ProductStatus.danger:
        return AppTheme.instance.dangerColor;
      case ProductStatus.expired:
        return AppTheme.instance.dangerColor;
    }
  }

  Color _getStatusBgColor() {
    switch (product.status) {
      case ProductStatus.ok:
        return AppTheme.instance.okBgColor;
      case ProductStatus.warning:
        return AppTheme.instance.warningBgColor;
      case ProductStatus.danger:
      case ProductStatus.expired:
        return AppTheme.instance.dangerBgColor;
    }
  }

  String _getStatusText() {
    switch (product.status) {
      case ProductStatus.ok:
        return 'OK';
      case ProductStatus.warning:
        return 'Скоро';
      case ProductStatus.danger:
        return 'Скоро';
      case ProductStatus.expired:
        return 'Просрочено';
    }
  }

  String _getDaysText() {
    final days = product.daysLeft;
    if (days < 0) return '${-days} дн. назад';
    if (days == 0) return 'Истекает сегодня';
    return '$days дн.';
  }

  int _getOpenedDaysAgo() {
    if (!product.isOpened || product.openedDate == null) return 0;
    final now = DateTime.now();
    return now.difference(product.openedDate!).inDays;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppTheme.instance.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppTheme.instance.borderColor),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.imageUrl != null) ...[
                    Container(
                      width: 44,
                      height: 44,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.instance.borderColor),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: Image.network(
                          product.imageUrl!.startsWith('/') ? '/api${product.imageUrl}' : product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.image_not_supported,
                            size: 20,
                            color: AppTheme.instance.textLightColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.instance.textColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          Categories.getCategoryName(product.type, product.category),
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.instance.textLightColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.more_vert, color: AppTheme.instance.textLightColor, size: 18),
                      onSelected: (value) {
                        if (value == 'edit') onEdit();
                        if (value == 'delete') onDelete();
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 16),
                              SizedBox(width: 6),
                              Text('Изменить', style: TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 16, color: AppTheme.instance.dangerColor),
                              const SizedBox(width: 6),
                              Text('Удалить', style: TextStyle(fontSize: 13, color: AppTheme.instance.dangerColor)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (product.isOpened) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 10, color: AppTheme.instance.textLightColor),
                    const SizedBox(width: 3),
                    Text(
                      'Вскрыто ${_getOpenedDaysAgo()} дн.',
                      style: TextStyle(fontSize: 10, color: AppTheme.instance.textLightColor),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusBgColor(),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_getStatusText()} · ${_getDaysText()}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _getStatusColor(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
