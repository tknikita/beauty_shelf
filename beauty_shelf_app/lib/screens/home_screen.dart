import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';
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
  final _api = ApiService();
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
  }

  @override
  void dispose() {
    AppTheme.instance.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final products = await _api.getProducts();
      setState(() {
        _products = products;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Не удалось загрузить';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredProducts = _products.where((p) {
        if (_typeFilter != 'all' && p.type != _typeFilter) return false;
        if (_categoryFilter != null && p.category != _categoryFilter) return false;
        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          if (!p.name.toLowerCase().contains(q) &&
              !(p.purpose?.toLowerCase().contains(q) ?? false)) {
            return false;
          }
        }
        return true;
      }).toList();
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
            if (p.id == null) {
              await _api.createProduct(p);
            } else {
              await _api.updateProduct(p);
            }
            _loadProducts();
            _showSnackBar(p.id == null ? 'Продукт добавлен' : 'Продукт обновлён');
          } catch (e) {
            _showSnackBar('Ошибка сохранения');
          }
        },
      ),
    );
  }

  void _confirmDelete(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.instance.surfaceColor,
        title: Text('Удалить продукт?', style: TextStyle(color: AppTheme.instance.textColor)),
        content: Text('Это действие нельзя отменить.', style: TextStyle(color: AppTheme.instance.textColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _api.deleteProduct(product.id!);
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
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
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
        padding: const EdgeInsets.all(20),
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
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              color: theme.surfaceColor,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                        'Beauty Shelf',
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
          ),
          // Filters row
          SliverPersistentHeader(
            delegate: _FilterHeaderDelegate(
              typeFilter: _typeFilter,
              categoryFilter: _categoryFilter,
              sortField: _sortField,
              sortOrder: _sortOrder,
              onTypeChanged: _setTypeFilter,
              onCategoryChanged: _setCategoryFilter,
              onToggleSort: _toggleSort,
              getSortIcon: _getSortIcon,
            ),
            pinned: true,
          ),
          // Products
          if (_isLoading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            SliverFillRemaining(child: _buildError())
          else if (_filteredProducts.isEmpty)
            SliverFillRemaining(child: _buildEmpty())
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final p = _sortedFilteredProducts[index];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: ProductCard(
                      product: p,
                      onEdit: () => _showEditModal(p),
                      onDelete: () => _confirmDelete(p),
                    ),
                  );
                },
                childCount: _sortedFilteredProducts.length,
              ),
            ),
        ],
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

class _FilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String typeFilter;
  final String? categoryFilter;
  final SortField sortField;
  final SortOrder sortOrder;
  final Function(String) onTypeChanged;
  final Function(String?) onCategoryChanged;
  final Function(SortField) onToggleSort;
  final IconData Function(SortField) getSortIcon;

  _FilterHeaderDelegate({
    required this.typeFilter,
    required this.categoryFilter,
    required this.sortField,
    required this.sortOrder,
    required this.onTypeChanged,
    required this.onCategoryChanged,
    required this.onToggleSort,
    required this.getSortIcon,
  });

  @override
  double get minExtent => 96;

  @override
  double get maxExtent => 96;

  Map<String, String> _getCategories() {
    final allCategories = <String, String>{};
    for (final type in ['care', 'decorative']) {
      final cats = AppTheme.instance.getCategoriesByType(type);
      allCategories.addAll(cats);
    }
    final sortedKeys = allCategories.keys.toList()
      ..sort((a, b) => allCategories[a]!.compareTo(allCategories[b]!));
    return {for (final k in sortedKeys) k: allCategories[k]!};
  }

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final theme = AppTheme.instance;
    final categories = _getCategories();
    
    Map<String, String> categoryItems;
    if (typeFilter == 'all') {
      categoryItems = {'all': 'Все', ...categories};
    } else {
      categoryItems = {'all': 'Все', ...AppTheme.instance.getCategoriesByType(typeFilter)};
      final sortedKeys = categoryItems.keys.toList()
        ..sort((a, b) {
          if (a == 'all') return -1;
          if (b == 'all') return 1;
          return categoryItems[a]!.compareTo(categoryItems[b]!);
        });
      categoryItems = {for (final k in sortedKeys) k: categoryItems[k]!};
    }

    return Container(
      color: theme.surfaceColor,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          // Type dropdown
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: theme.backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.borderColor),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: typeFilter,
                  isExpanded: true,
                  icon: Icon(Icons.keyboard_arrow_down, color: theme.textLightColor, size: 20),
                  style: TextStyle(fontSize: 13, color: theme.textColor),
                  dropdownColor: theme.surfaceColor,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Все')),
                    DropdownMenuItem(value: 'care', child: Text('Уход')),
                    DropdownMenuItem(value: 'decorative', child: Text('Декор.')),
                  ],
                  onChanged: (v) {
                    if (v != null) onTypeChanged(v);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Category dropdown
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: theme.backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.borderColor),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: categoryFilter ?? 'all',
                  isExpanded: true,
                  icon: Icon(Icons.keyboard_arrow_down, color: theme.textLightColor, size: 20),
                  style: TextStyle(fontSize: 13, color: theme.textColor),
                  dropdownColor: theme.surfaceColor,
                  items: categoryItems.entries
                      .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                      .toList(),
                  onChanged: (v) => onCategoryChanged(v == 'all' ? null : v),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Sort button
          _SortButton(
            field: sortField,
            order: sortOrder,
            onTap: onToggleSort,
            getIcon: getSortIcon,
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _FilterHeaderDelegate oldDelegate) => true;
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
