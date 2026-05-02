import 'dart:io';
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

  (Color, Color) _getStatusStyle() {
    final days = product.daysLeft;
    if (days < 0) return (AppTheme.instance.expiredColor, AppTheme.instance.expiredBgColor);
    if (days <= 1) return (AppTheme.instance.todayColor, AppTheme.instance.todayBgColor);
    if (days < 30) return (AppTheme.instance.warningColor, AppTheme.instance.warningBgColor);
    return (AppTheme.instance.neutralColor, AppTheme.instance.neutralBgColor);
  }

  String _getStatusText() {
    final days = product.daysLeft;
    if (days < 0) return '${-days} дн.';
    if (days == 0) return 'Сегодня';
    if (days == 1) return '1 дн.';
    return '$days дн.';
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
      child: InkWell(
        onTap: () {}, // Disabled - swipe handles navigation
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Thumbnail
              GestureDetector(
                onTap: () => _showImagePreview(context, product),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: product.imageUrl != null
                        ? null
                        : theme.primaryColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.borderColor),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: _buildProductImage(product, theme),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Meta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Categories.getCategoryName(product.type, product.category),
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.textLightColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getStatusText(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Menu
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
      ),
    );
  }

  Widget _buildProductImage(Product product, AppTheme theme) {
    if (product.effectiveImageUrl == null) {
      return _buildPlaceholder(theme);
    }
    
    const size = 112; // 2x for retina
    
    // Local file
    if (product.isLocalImage) {
      return Image.file(
        File(product.effectiveImageUrl!),
        fit: BoxFit.cover,
        cacheWidth: size,
        cacheHeight: size,
        errorBuilder: (_, __, ___) => _buildPlaceholder(theme),
      );
    }
    
    // Remote URL
    return Image.network(
      product.effectiveImageUrl!,
      fit: BoxFit.cover,
      cacheWidth: size,
      cacheHeight: size,
      errorBuilder: (_, __, ___) => _buildPlaceholder(theme),
    );
  }

  Widget _buildPlaceholder(AppTheme theme) {
    return Icon(Icons.inventory_2_outlined, size: 24, color: theme.textLightColor);
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
                      errorBuilder: (_, __, ___) => _buildPreviewError(theme),
                    )
                  : Image.network(
                      product.effectiveImageUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => _buildPreviewError(theme),
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
