import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/product.dart';
import '../services/storage_service.dart';
import '../services/storage_factory.dart';
import '../services/notification_service.dart';
import '../utils/sorting.dart';
import '../widgets/product_card.dart';
import '../widgets/product_form.dart';
import '../theme/app_theme.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storage = createStorageService();
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  String? _error;
  
  String _typeFilter = 'all';
  String? _categoryFilter;
  String _searchQuery = '';
  
  // Sorting
  SortField _sortField = SortField.expiry;
  SortOrder _sortOrder = SortOrder.asc;
  
  List<Product> get _sortedFilteredProducts {
    return sortProducts(_filteredProducts, _sortField, _sortOrder);
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
  void initState() {
    super.initState();
    AppTheme.instance.addListener(_onThemeChanged);
    _loadProducts();
    _checkExpiring();
  }

  @override
  void dispose() {
    AppTheme.instance.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  Future<void> _checkExpiring() async {
    try {
      await NotificationService().checkAndNotifyExpiringProducts();
    } catch (_) {
      // Silently ignore notification errors
    }
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final products = await _storage.getAllProducts();
      final filtered = _filterProducts(products);
      setState(() {
        _products = products;
        _filteredProducts = filtered;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Не удалось загрузить';
        _isLoading = false;
      });
    }
  }

  List<Product> _filterProducts(List<Product> products) {
    return products.where((p) {
      if (_typeFilter != 'all' && p.type != _typeFilter) return false;
      if (_categoryFilter != null) {
        // A group filter matches every leaf inside it; a leaf matches itself.
        final allowed =
            AppTheme.instance.resolveCategoryFilter(p.type, _categoryFilter!);
        if (!allowed.contains(p.category)) return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!p.name.toLowerCase().contains(q) &&
            !(p.brand?.toLowerCase().contains(q) ?? false) &&
            !(p.purpose?.toLowerCase().contains(q) ?? false)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  void _applyFilters() {
    setState(() {
      _filteredProducts = _filterProducts(_products);
    });
  }

  void _setTypeFilter(String filter) {
    setState(() {
      _typeFilter = filter;
      _categoryFilter = null;
      _applyFilters();
    });
  }

  void _setCategoryFilter(String? category) {
    setState(() {
      _categoryFilter = category;
      _applyFilters();
    });
  }

  void _showAddModal() {
    _showFormModal(null);
  }

  void _showEditModal(Product product) {
    _showFormModal(product);
  }

  Future<void> _changeQuantity(Product product, int quantity) async {
    if (quantity < 1 || quantity == product.quantity) return;
    try {
      await _storage.updateProduct(product.copyWith(quantity: quantity));
      _loadProducts();
    } catch (e) {
      _showSnackBar('Ошибка обновления количества');
    }
  }

  /// Manual reordering is only offered when the list is not filtered/searched.
  bool get _manualOrder =>
      _sortField == SortField.position &&
      _searchQuery.isEmpty &&
      _typeFilter == 'all' &&
      _categoryFilter == null;

  Future<void> _onReorderProducts(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    final list = List<Product>.of(_sortedFilteredProducts);
    final moved = list.removeAt(oldIndex);
    list.insert(newIndex, moved);
    for (var i = 0; i < list.length; i++) {
      final p = list[i];
      if (p.id != null && p.position != i) {
        await _storage.updateProduct(p.copyWith(position: i));
      }
    }
    _loadProducts();
  }

  void _showFormModal(Product? product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.instance.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ProductForm(
        product: product,
        onSave: (p) async {
          Navigator.pop(context);
          try {
            final notificationService = NotificationService();

            if (p.id == null) {
              final created = await _storage.createProduct(p);
              // Schedule notification for new product
              await notificationService.scheduleProductNotification(created);
            } else {
              await _storage.updateProduct(p);
              // Cancel old notification and schedule new one
              await notificationService.cancelProductNotification(p.id!);
              await notificationService.scheduleProductNotification(p);
            }
            _loadProducts();
            _showSnackBar(p.id == null ? 'Продукт добавлен' : 'Продукт обновлён');
          } catch (e, stack) {
            debugPrint('Save error: $e\n$stack');
            _showSnackBar('Ошибка сохранения: $e');
          }
        },
      ),
    );
  }

  void _confirmDelete(Product product) {
    showDialog(
      context: context,
      builder: (context) {
        final bottomPadding = MediaQuery.of(context).padding.bottom;
        return AlertDialog(
          backgroundColor: AppTheme.instance.surfaceColor,
          title: Text('Удалить продукт?', style: TextStyle(color: AppTheme.instance.textColor)),
          content: Text('Это действие нельзя отменить.', style: TextStyle(color: AppTheme.instance.textColor)),
          contentPadding: EdgeInsets.fromLTRB(24, 20, 24, 20 + bottomPadding),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  // Cancel notification first
                  final notificationService = NotificationService();
                  await notificationService.cancelProductNotification(product.id!);
                  await _storage.deleteProduct(product.id!);
                  _loadProducts();
                  _showSnackBar('Продукт удалён');
                } catch (e) {
                  _showSnackBar('Ошибка удаления');
                }
              },
              style: FilledButton.styleFrom(backgroundColor: AppTheme.instance.expiredColor),
              child: const Text('Удалить'),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(left: 16, right: 16, top: 16),
      ),
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }

  Widget _buildExpiringBanner() {
    final theme = AppTheme.instance;
    final expiringCount = _products.where((p) => p.daysLeft >= 0 && p.daysLeft <= 30).length;
    final expiredCount = _products.where((p) => p.daysLeft < 0).length;
    
    if (expiringCount == 0 && expiredCount == 0) {
      return const SizedBox.shrink();
    }
    
    return GestureDetector(
      onTap: () => _showExpiringProducts(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: expiredCount > 0 ? theme.expiredBgColor : theme.warningBgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              expiredCount > 0 ? Icons.warning : Icons.access_time,
              size: 18,
              color: expiredCount > 0 ? theme.expiredColor : theme.warningColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                expiredCount > 0
                    ? '$expiredCount просрочено'
                    : '$expiringCount скоро истекает',
                style: TextStyle(
                  fontSize: 13,
                  color: expiredCount > 0 ? theme.expiredColor : theme.warningColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              'Подробнее →',
              style: TextStyle(
                fontSize: 12,
                color: expiredCount > 0 ? theme.expiredColor : theme.warningColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExpiringProducts() {
    final theme = AppTheme.instance;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final expiring = _products.where((p) => p.daysLeft <= 30).toList()
      ..sort((a, b) => a.daysLeft.compareTo(b.daysLeft));
    
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        color: theme.surfaceColor,
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Истекающие продукты',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: theme.textColor),
            ),
            const SizedBox(height: 16),
            if (expiring.isEmpty)
              Text('Нет продуктов для отображения', style: TextStyle(color: theme.textLightColor))
            else
              ...expiring.take(10).map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: p.daysLeft < 0 
                            ? theme.expiredColor 
                            : p.daysLeft <= 7 
                                ? theme.warningColor 
                                : theme.neutralColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(p.name, style: TextStyle(color: theme.textColor))),
                    Text(
                      p.daysLeft < 0 
                          ? 'Просрочено' 
                          : '${p.daysLeft} дн.',
                      style: TextStyle(
                        color: p.daysLeft < 0 
                            ? theme.expiredColor 
                            : theme.textLightColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.instance;
    
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      resizeToAvoidBottomInset: false,
      body: Builder(
        builder: (ctx) => MediaQuery(
          data: MediaQuery.of(ctx).removeViewInsets(removeBottom: true),
          child: SafeArea(
        child: Column(
          children: [
            // Header section
            Container(
              color: theme.surfaceColor,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Полочка',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: theme.textColor,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined),
                        onPressed: _openSettings,
                        color: theme.textLightColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildExpiringBanner(),
                  const SizedBox(height: 8),
                  TextField(
                    onChanged: (v) {
                      setState(() {
                        _searchQuery = v;
                        _applyFilters();
                      });
                    },
                    style: TextStyle(color: theme.textColor),
                    decoration: InputDecoration(
                      hintText: 'Поиск...',
                      hintStyle: TextStyle(color: theme.textLightColor),
                      prefixIcon: Icon(Icons.search, color: theme.textLightColor, size: 20),
                      filled: true,
                      fillColor: theme.backgroundColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
          // Filters row - use regular Container instead of SliverPersistentHeader
          Container(
            color: theme.surfaceColor,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: theme.backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.borderColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _typeFilter,
                        isExpanded: true,
                        icon: Icon(Icons.keyboard_arrow_down, color: theme.textLightColor, size: 18),
                        style: TextStyle(fontSize: 12, color: theme.textColor),
                        dropdownColor: theme.surfaceColor,
                        items: [
                          const DropdownMenuItem(value: 'all', child: Text('Все')),
                          ...AppTheme.instance.visibleTypes().map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text(AppTheme.instance.typeName(t)),
                            ),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) _setTypeFilter(v);
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: theme.backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.borderColor),
                    ),
                    child: _CategoryDropdown(
                      typeFilter: _typeFilter,
                      categoryFilter: _categoryFilter,
                      onChanged: _setCategoryFilter,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _SortButton(
                  field: _sortField,
                  order: _sortOrder,
                  onTap: _toggleSort,
                  getIcon: _getSortIcon,
                ),
              ],
            ),
          ),
          // Products list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildError()
                    : _filteredProducts.isEmpty
                        ? _buildEmpty()
                        : _manualOrder
                            ? ReorderableListView.builder(
                                padding: const EdgeInsets.only(top: 4, bottom: 80),
                                buildDefaultDragHandles: false,
                                itemCount: _sortedFilteredProducts.length,
                                onReorder: _onReorderProducts,
                                itemBuilder: (context, index) {
                                  final p = _sortedFilteredProducts[index];
                                  return KeyedSubtree(
                                    key: ValueKey('product_${p.id}'),
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                                      child: _SwipeableProductCard(
                                        product: p,
                                        onEdit: () => _showEditModal(p),
                                        onDelete: () => _confirmDelete(p),
                                        onQuantityChanged: (q) => _changeQuantity(p, q),
                                        reorderIndex: index,
                                      ),
                                    ),
                                  );
                                },
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.only(top: 4, bottom: 80),
                                itemCount: _sortedFilteredProducts.length,
                                itemBuilder: (context, index) {
                                  final p = _sortedFilteredProducts[index];
                                  return Padding(
                                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                                    child: _SwipeableProductCard(
                                      product: p,
                                      onEdit: () => _showEditModal(p),
                                      onDelete: () => _confirmDelete(p),
                                      onQuantityChanged: (q) => _changeQuantity(p, q),
                                    ),
                                  );
                                },
                              ),
          ),
        ],
      ),
      ),
          ),
        ),
      floatingActionButton: SizedBox(
        width: 56,
        height: 56,
        child: FloatingActionButton(
          onPressed: _showAddModal,
          backgroundColor: theme.primaryColor,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildError() {
    final theme = AppTheme.instance;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.textLightColor),
          const SizedBox(height: 16),
          Text('Не удалось загрузить', style: TextStyle(fontSize: 16, color: theme.textColor)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _loadProducts,
            child: Text('Повторить', style: TextStyle(color: theme.primaryColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    final theme = AppTheme.instance;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: theme.textLightColor),
          const SizedBox(height: 16),
          Text(
            _products.isEmpty ? 'Полка пуста' : 'Ничего не найдено',
            style: TextStyle(fontSize: 18, color: theme.textColor),
          ),
          const SizedBox(height: 8),
          Text(
            _products.isEmpty
                ? 'Нажмите + чтобы добавить первый продукт'
                : 'Попробуйте изменить фильтры',
            style: TextStyle(fontSize: 14, color: theme.textLightColor),
          ),
        ],
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  final SortField field;
  final SortOrder order;
  final Function(SortField) onTap;
  final IconData Function(SortField) getIcon;

  const _SortButton({
    required this.field,
    required this.order,
    required this.onTap,
    required this.getIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.instance;
    return PopupMenuButton<SortField>(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.borderColor),
        ),
        child: Icon(Icons.swap_vert, size: 20, color: theme.textLightColor),
      ),
      onSelected: onTap,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: SortField.expiry,
          child: _buildSortItem('По сроку', SortField.expiry),
        ),
        PopupMenuItem(
          value: SortField.name,
          child: _buildSortItem('По названию', SortField.name),
        ),
        PopupMenuItem(
          value: SortField.category,
          child: _buildSortItem('По категории', SortField.category),
        ),
        PopupMenuItem(
          value: SortField.position,
          child: _buildSortItem('Вручную', SortField.position),
        ),
      ],
    );
  }

  Widget _buildSortItem(String label, SortField sortField) {
    final theme = AppTheme.instance;
    final isSelected = field == sortField;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? theme.primaryColor : theme.textColor,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        if (isSelected)
          Icon(
            order == SortOrder.asc ? Icons.arrow_upward : Icons.arrow_downward,
            size: 16,
            color: theme.primaryColor,
          ),
      ],
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  final String typeFilter;
  final String? categoryFilter;
  final Function(String?) onChanged;

  const _CategoryDropdown({
    required this.typeFilter,
    required this.categoryFilter,
    required this.onChanged,
  });

  /// "Все" + one-level tree: selectable group rows (filter by all children)
  /// with indented leaves below.
  List<DropdownMenuItem<String>> _buildItems(AppTheme theme) {
    final items = <DropdownMenuItem<String>>[
      const DropdownMenuItem(value: 'all', child: Text('Все')),
    ];
    final types =
        typeFilter == 'all' ? AppTheme.instance.visibleTypes() : [typeFilter];
    for (final type in types) {
      for (final group in AppTheme.instance.getCategoryTree(type)) {
        if (!group.isUngrouped) {
          items.add(DropdownMenuItem<String>(
            value: group.key,
            child: Text(
              group.name,
              style: TextStyle(fontWeight: FontWeight.w600, color: theme.textColor),
            ),
          ));
        }
        for (final leaf in group.leaves.entries) {
          items.add(DropdownMenuItem<String>(
            value: leaf.key,
            child: Padding(
              padding: EdgeInsets.only(left: group.isUngrouped ? 0 : 12),
              child: Text(leaf.value),
            ),
          ));
        }
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.instance;
    final items = _buildItems(theme);
    final value =
        items.any((i) => i.value == categoryFilter) ? categoryFilter! : 'all';

    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        icon: Icon(Icons.keyboard_arrow_down, color: theme.textLightColor, size: 18),
        style: TextStyle(fontSize: 12, color: theme.textColor),
        dropdownColor: theme.surfaceColor,
        items: items,
        onChanged: (v) => onChanged(v == 'all' ? null : v),
      ),
    );
  }
}

class _SwipeableProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<int>? onQuantityChanged;
  final int? reorderIndex;

  const _SwipeableProductCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
    this.onQuantityChanged,
    this.reorderIndex,
  });

  @override
  State<_SwipeableProductCard> createState() => _SwipeableProductCardState();
}

class _SwipeableProductCardState extends State<_SwipeableProductCard>
    with SingleTickerProviderStateMixin {
  double _dragExtent = 0;
  double _animationStartExtent = 0;
  bool _isDragging = false;
  late AnimationController _controller;

  static const _threshold = 0.25;
  static const _maxDragExtent = 120.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _controller.addListener(_onAnimationTick);
  }

  void _onAnimationTick() {
    if (!mounted) return;
    // Interpolate the drag extent (pixels) down to 0 using the controller.
    final eased = Curves.easeOut.transform(_controller.value);
    setState(() {
      _dragExtent = _animationStartExtent * (1 - eased);
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onAnimationTick);
    _controller.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _isDragging = true;
      _dragExtent = (_dragExtent + details.delta.dx)
          .clamp(-_maxDragExtent, _maxDragExtent);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final width = context.size?.width ?? 300;
    final ratio = _dragExtent.abs() / width;

    if (ratio > _threshold) {
      HapticFeedback.mediumImpact();
      if (_dragExtent < 0) {
        // Swipe left - delete
        widget.onDelete();
      } else {
        // Swipe right - edit
        widget.onEdit();
      }
    }

    // Animate the card back to its resting position.
    _animationStartExtent = _dragExtent;
    _controller.forward(from: 0).whenComplete(() {
      if (mounted) {
        setState(() {
          _dragExtent = 0;
          _isDragging = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.instance;
    final isDelete = _dragExtent < 0;
    final progress = (_dragExtent.abs() / _maxDragExtent).clamp(0.0, 1.0);

    return GestureDetector(
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      onTap: widget.onEdit,
      child: Stack(
        children: [
          // Background action
          if (_isDragging || _dragExtent != 0)
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isDelete
                      ? theme.expiredColor.withAlpha((progress * 255).toInt())
                      : theme.primaryColor.withAlpha((progress * 255).toInt()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment:
                      isDelete ? MainAxisAlignment.end : MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Icon(
                        isDelete ? Icons.delete_outline : Icons.edit_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Card
          Transform.translate(
            offset: Offset(_dragExtent, 0),
            child: Opacity(
              opacity: 1 - (progress * 0.3),
              child: ProductCard(
                product: widget.product,
                onEdit: widget.onEdit,
                onDelete: widget.onDelete,
                onQuantityChanged: widget.onQuantityChanged,
                reorderIndex: widget.reorderIndex,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
