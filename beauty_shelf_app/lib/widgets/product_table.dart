import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  Color _getStatusColor(ProductStatus status) {
    switch (status) {
      case ProductStatus.ok:
        return AppTheme.instance.okColor;
      case ProductStatus.warning:
        return AppTheme.instance.warningColor;
      case ProductStatus.danger:
      case ProductStatus.expired:
        return AppTheme.instance.dangerColor;
    }
  }

  Color _getStatusBgColor(ProductStatus status) {
    switch (status) {
      case ProductStatus.ok:
        return AppTheme.instance.okBgColor;
      case ProductStatus.warning:
        return AppTheme.instance.warningBgColor;
      case ProductStatus.danger:
      case ProductStatus.expired:
        return AppTheme.instance.dangerBgColor;
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
        border: Border.all(color: AppTheme.instance.borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppTheme.instance.backgroundColor),
            dataRowColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.hovered)) {
                return AppTheme.instance.backgroundColor;
              }
              return Colors.white;
            }),
            columnSpacing: 24,
            horizontalMargin: 16,
            columns: [
              DataColumn(label: Text('Название', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.instance.textLightColor))),
              DataColumn(label: Text('Тип', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.instance.textLightColor))),
              DataColumn(label: Text('Категория', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.instance.textLightColor))),
              DataColumn(label: Text('Годен до', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.instance.textLightColor))),
              DataColumn(label: Text('Статус', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.instance.textLightColor))),
              const DataColumn(label: Text('')),
            ],
            rows: products.map((p) {
              return DataRow(
                cells: [
                  DataCell(Text(p.name, style: TextStyle(fontWeight: FontWeight.w500, color: AppTheme.instance.textColor))),
                  DataCell(Text(p.type == 'care' ? 'Уход' : 'Декор.', style: TextStyle(color: AppTheme.instance.textLightColor))),
                  DataCell(Text(Categories.getCategoryName(p.type, p.category), style: TextStyle(color: AppTheme.instance.textLightColor))),
                  DataCell(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_formatDate(p.effectiveExpiryDate), style: TextStyle(color: AppTheme.instance.textColor)),
                        if (p.isOpened)
                          Text(
                            'Вскрыто ${_getOpenedDaysAgo(p)} дн.',
                            style: TextStyle(fontSize: 11, color: AppTheme.instance.textLightColor),
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
                          color: AppTheme.instance.textLightColor,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          onPressed: () => onDelete(p),
                          color: AppTheme.instance.dangerColor,
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
