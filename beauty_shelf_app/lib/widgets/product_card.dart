import 'package:flutter/material.dart';
import '../models/product.dart';

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
        return const Color(0xFF5A9E6F);
      case ProductStatus.warning:
        return const Color(0xFFC47B3D);
      case ProductStatus.danger:
        return const Color(0xFFB85C6A);
      case ProductStatus.expired:
        return const Color(0xFFD9848C);
    }
  }

  Color _getStatusBgColor() {
    switch (product.status) {
      case ProductStatus.ok:
        return const Color(0xFFF0F7F2);
      case ProductStatus.warning:
        return const Color(0xFFFDF5F0);
      case ProductStatus.danger:
      case ProductStatus.expired:
        return const Color(0xFFFDF0F2);
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
        side: const BorderSide(color: Color(0xFFE8E8E8)),
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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.type == 'care' ? 'Уходовая' : 'Декоративная',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.grey[400], size: 20),
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
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: Color(0xFFD9848C)),
                          SizedBox(width: 8),
                          Text('Удалить', style: TextStyle(color: Color(0xFFD9848C))),
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
                    Icon(Icons.calendar_today, size: 12, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      'Вскрыто ${_getOpenedDaysAgo()} дн. назад',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
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
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
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
