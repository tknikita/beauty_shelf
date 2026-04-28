import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';

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

  Color _getStatusColor(ProductStatus status) {
    switch (status) {
      case ProductStatus.ok:
        return const Color(0xFF5A9E6F);
      case ProductStatus.warning:
        return const Color(0xFFC47B3D);
      case ProductStatus.danger:
      case ProductStatus.expired:
        return const Color(0xFFB85C6A);
    }
  }

  Color _getStatusBgColor(ProductStatus status) {
    switch (status) {
      case ProductStatus.ok:
        return const Color(0xFFF0F7F2);
      case ProductStatus.warning:
        return const Color(0xFFFDF5F0);
      case ProductStatus.danger:
      case ProductStatus.expired:
        return const Color(0xFFFDF0F2);
    }
  }

  String _getStatusText(ProductStatus status) {
    switch (status) {
      case ProductStatus.ok:
        return 'OK';
      case ProductStatus.warning:
        return 'Скоро';
      case ProductStatus.danger:
        return '<30 дн.';
      case ProductStatus.expired:
        return 'Просрочено';
    }
  }

  int _getOpenedDaysAgo(Product p) {
    if (!p.isOpened || p.openedDate == null) return 0;
    return DateTime.now().difference(p.openedDate!).inDays;
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy', 'ru_RU').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFFDF9FA)),
            dataRowColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.hovered)) {
                return const Color(0xFFFDF9FA);
              }
              return Colors.white;
            }),
            columnSpacing: 24,
            horizontalMargin: 16,
            columns: const [
              DataColumn(label: Text('Название', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF8A8A8A)))),
              DataColumn(label: Text('Тип', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF8A8A8A)))),
              DataColumn(label: Text('Категория', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF8A8A8A)))),
              DataColumn(label: Text('Годен до', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF8A8A8A)))),
              DataColumn(label: Text('Статус', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF8A8A8A)))),
              DataColumn(label: Text('')),
            ],
            rows: products.map((p) {
              return DataRow(
                cells: [
                  DataCell(Text(p.name, style: const TextStyle(fontWeight: FontWeight.w500))),
                  DataCell(Text(p.type == 'care' ? 'Уход' : 'Декор.', style: TextStyle(color: Colors.grey[600]))),
                  DataCell(Text(Categories.getCategoryName(p.type, p.category), style: TextStyle(color: Colors.grey[600]))),
                  DataCell(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_formatDate(p.effectiveExpiryDate)),
                        if (p.isOpened)
                          Text(
                            'Вскрыто ${_getOpenedDaysAgo(p)} дн.',
                            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                          ),
                      ],
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusBgColor(p.status),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getStatusText(p.status),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _getStatusColor(p.status),
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: () => onEdit(p),
                          color: Colors.grey[400],
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          onPressed: () => onDelete(p),
                          color: const Color(0xFFD9848C),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
