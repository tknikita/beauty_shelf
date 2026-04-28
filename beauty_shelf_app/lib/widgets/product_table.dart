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
    final theme = AppTheme.instance;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.backgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                _headerCell('Название', flex: 3),
                _headerCell('Тип', flex: 1),
                _headerCell('Годен до', flex: 2),
                _headerCell('Статус', flex: 1),
                const SizedBox(width: 80),
              ],
            ),
          ),
          // Rows
          ...products.map((p) => _buildRow(p, theme)).toList(),
          // Empty state
          if (products.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Нет продуктов',
                style: TextStyle(color: theme.textLightColor),
              ),
            ),
        ],
      ),
    );
  }

  Widget _headerCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.instance.textLightColor,
        ),
      ),
    );
  }

  Widget _buildRow(Product p, dynamic theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.borderColor, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: _buildNameCell(p, theme)),
          Expanded(flex: 1, child: _buildTypeCell(p, theme)),
          Expanded(flex: 2, child: _buildExpiryCell(p, theme)),
          Expanded(flex: 1, child: _buildStatusCell(p)),
          SizedBox(
            width: 80,
            child: _buildActionsCell(p, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildNameCell(Product p, dynamic theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          p.name,
          style: TextStyle(fontWeight: FontWeight.w500, color: theme.textColor),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          Categories.getCategoryName(p.type, p.category),
          style: TextStyle(fontSize: 12, color: theme.textLightColor),
        ),
      ],
    );
  }

  Widget _buildTypeCell(Product p, dynamic theme) {
    return Text(
      p.type == 'care' ? 'Уход' : 'Декор.',
      style: TextStyle(fontSize: 13, color: theme.textLightColor),
    );
  }

  Widget _buildExpiryCell(Product p, dynamic theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _formatDate(p.effectiveExpiryDate),
          style: TextStyle(fontSize: 13, color: theme.textColor),
        ),
        if (p.isOpened)
          Text(
            'Вскрыто ${_getOpenedDaysAgo(p)} дн.',
            style: TextStyle(fontSize: 11, color: theme.textLightColor),
          ),
      ],
    );
  }

  Widget _buildStatusCell(Product p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusBgColor(p.status),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getStatusText(p.status),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _getStatusColor(p.status),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildActionsCell(Product p, dynamic theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 18),
          onPressed: () => onEdit(p),
          color: theme.textLightColor,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          padding: EdgeInsets.zero,
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 18),
          onPressed: () => onDelete(p),
          color: theme.dangerColor,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }
}
