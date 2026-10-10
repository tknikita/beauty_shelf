import 'dart:io';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<int>? onQuantityChanged;
  final int? reorderIndex;

  const ProductCard({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onDelete,
    this.onQuantityChanged,
    this.reorderIndex,
  });

  (Color, Color) _getStatusStyle() {
    final days = product.daysLeft;
    if (days < 0) return (AppTheme.instance.expiredColor, AppTheme.instance.expiredBgColor);
    if (days <= 1) return (AppTheme.instance.todayColor, AppTheme.instance.todayBgColor);
    if (days < 30) return (AppTheme.instance.warningColor, AppTheme.instance.warningBgColor);
    return (AppTheme.instance.neutralColor, AppTheme.instance.neutralBgColor);
  }

  String _getStatusText() {
    final days = product.daysLeft;
    if (days < 0) return 'Просрочено · ${-days} дн.';
    if (days == 0) return 'Сегодня';
    if (days < 30) return 'Скоро · $days дн.';
    return 'OK · $days дн.';
  }

  String _subtitle() {
    final category = Categories.getCategoryName(product.type, product.category);
    final brand = product.brand?.trim();
    if (brand != null && brand.isNotEmpty) return '$brand · $category';
    return category;
  }

  String _getDateText() {
    final d = product.effectiveExpiryDate;
    return 'до ${d.day.toString().padLeft(2, '0')}.'
        '${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.instance;
    final (statusColor, statusBgColor) = _getStatusStyle();

    return Card(
      elevation: 0,
      color: theme.surfaceColor,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Full-height media, cropped to fill the card.
                GestureDetector(
                  onTap: () => _showImagePreview(context, product),
                  child: SizedBox(
                    width: 76,
                    child: _buildProductImage(product, theme),
                  ),
                ),
                // Meta
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 0, 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: theme.textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _subtitle(),
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.textLightColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusBgColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _getStatusText(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                            ),
                            // Opened-package indicator.
                            if (product.isOpened) ...[
                              const SizedBox(width: 6),
                              Tooltip(
                                message: 'Вскрыта упаковка',
                                child: Icon(
                                  Icons.lock_open,
                                  size: 15,
                                  color: theme.textLightColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getDateText(),
                          style: TextStyle(fontSize: 12, color: theme.textLightColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                // Width reserved for the right-hand controls (overflow menu and,
                // when present, the quantity stepper). They are painted as an
                // overlay below, so they never steal width from the text.
                const SizedBox(width: 56),
              ],
            ),
          ),
          // Right-hand controls as overlays so they don't affect the row layout
          // (the metadata text keeps its full width and the card height is the
          // same with or without the stepper): the overflow menu sits at the
          // top-right, the quantity stepper at the bottom-right.
          Positioned(
            top: 0,
            right: 4,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (reorderIndex != null)
                  ReorderableDragStartListener(
                    index: reorderIndex!,
                    child: Icon(
                      Icons.drag_indicator,
                      color: theme.textLightColor,
                      size: 20,
                    ),
                  ),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.more_vert, color: theme.textLightColor, size: 20),
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
                          SizedBox(width: 8),
                          Text('Изменить', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                          const SizedBox(width: 8),
                          const Text('Удалить', style: TextStyle(fontSize: 13, color: Colors.redAccent)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (onQuantityChanged != null && product.quantity > 1)
            Positioned(
              right: 4,
              bottom: 10,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: _QuantityStepper(
                  quantity: product.quantity,
                  theme: theme,
                  onChanged: onQuantityChanged!,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductImage(Product product, AppTheme theme) {
    final url = product.effectiveImageUrl;
    if (url == null) return _buildPlaceholder(theme);

    // Cropped to fill the whole media panel.
    if (product.isLocalImage) {
      return Image.file(
        File(url),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildPlaceholder(theme),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _buildPlaceholder(theme),
    );
  }

  Widget _buildPlaceholder(AppTheme theme) {
    return Container(
      color: theme.primaryColor.withAlpha(20),
      alignment: Alignment.center,
      child: Icon(
        Icons.inventory_2_outlined,
        size: 40,
        color: theme.primaryColor.withAlpha(150),
      ),
    );
  }
}

Widget _buildPreviewError(AppTheme theme) {
  return Container(
    padding: const EdgeInsets.all(40),
    decoration: BoxDecoration(
      color: theme.surfaceColor,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(
      Icons.image_not_supported,
      size: 64,
      color: theme.textLightColor,
    ),
  );
}

void _showImagePreview(BuildContext context, Product product) {
  if (product.imageUrl == null) return;
  
  final theme = AppTheme.instance;
  final isLocal = product.isLocalImage;
  
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: isLocal
                  ? Image.file(
                      File(product.effectiveImageUrl!),
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => _buildPreviewError(theme),
                    )
                  : Image.network(
                      product.effectiveImageUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => _buildPreviewError(theme),
                    ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.isDarkMode ? Colors.black54 : Colors.white70,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, color: theme.textColor, size: 24),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Compact "− N +" control shown on the card.
class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final AppTheme theme;
  final ValueChanged<int> onChanged;

  const _QuantityStepper({
    required this.quantity,
    required this.theme,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn(Icons.remove, quantity > 1 ? () => onChanged(quantity - 1) : null),
          SizedBox(
            width: 22,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
          ),
          _btn(Icons.add, () => onChanged(quantity + 1)),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Icon(
          icon,
          size: 20,
          color: onTap == null
              ? theme.textLightColor.withAlpha(80)
              : theme.primaryColor,
        ),
      ),
    );
  }
}
