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
    if (days < 0) return 'Просрочено ${-days} дн.';
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.instance.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.instance.textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.type == 'care' ? 'Уходовая' : 'Декоративная',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.instance.textLightColor,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: AppTheme.instance.textLightColor, size: 20),
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Изменить'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: AppTheme.instance.dangerColor),
                          const SizedBox(width: 8),
                          Text('Удалить', style: TextStyle(color: AppTheme.instance.dangerColor)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetail('Категория:', Categories.getCategoryName(product.type, product.category)),
            if (product.purpose != null && product.purpose!.isNotEmpty)
              _buildDetail('Назначение:', product.purpose!),
            if (product.isOpened)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 12, color: AppTheme.instance.textLightColor),
                    const SizedBox(width: 4),
                    Text(
                      'Вскрыто ${_getOpenedDaysAgo()} дн. назад',
                      style: TextStyle(fontSize: 11, color: AppTheme.instance.textLightColor),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusBgColor(),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_getStatusText()} · ${_getDaysText()}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _getStatusColor(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 13, color: AppTheme.instance.textLightColor),
          children: [
            TextSpan(
              text: label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const TextSpan(text: ' '),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
