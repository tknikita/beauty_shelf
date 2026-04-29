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
    return getSortIcon(_sortField, field, _sortOrder);
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
            style: FilledButton.styleFrom(backgroundColor: AppTheme.instance.dangerColor),
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
          color: expiredCount > 0 ? theme.dangerBgColor : theme.warningBgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              expiredCount > 0 ? Icons.warning : Icons.access_time,
              size: 18,
              color: expiredCount > 0 ? theme.dangerColor : theme.warningColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                expiredCount > 0
                    ? '$expiredCount просрочено'
                    : '$expiringCount скоро истекает',
                style: TextStyle(
                  fontSize: 13,
                  color: expiredCount > 0 ? theme.dangerColor : theme.warningColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              'Подробнее →',
              style: TextStyle(
                fontSize: 12,
                color: expiredCount > 0 ? theme.dangerColor : theme.warningColor,
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
                            ? theme.dangerColor 
                            : p.daysLeft <= 7 
                                ? theme.warningColor 
                                : theme.okColor,
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
                            ? theme.dangerColor 
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
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        padding: EdgeInsets.zero,
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
                      prefixIcon: Icon(Icons.search, color: theme.textLightColor),
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
          // Filters + Sort in a pinned header
          SliverPersistentHeader(
            delegate: _FilterSortHeaderDelegate(
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
          if (_isLoading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            SliverFillRemaining(child: _buildError())
          else if (_filteredProducts.isEmpty)
            SliverFillRemaining(child: _buildEmpty())
          else
            _buildProductGrid(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddModal,
        backgroundColor: theme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
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
  
  Widget _buildProductGrid() {
    final products = _sortedFilteredProducts;
    return SliverPadding(
      padding: const EdgeInsets.all(12),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 320,
          childAspectRatio: 1.35,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final p = products[index];
            return ProductCard(
              product: p,
              onEdit: () => _showEditModal(p),
              onDelete: () => _confirmDelete(p),
            );
          },
          childCount: products.length,
        ),
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String value;
  final Map<String, String> items;
  final Function(String) onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.instance;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: theme.textLightColor, size: 20),
          style: TextStyle(fontSize: 13, color: theme.textColor),
          dropdownColor: theme.surfaceColor,
          items: items.entries.map((e) => DropdownMenuItem(
            value: e.key,
            child: Text(e.value, style: TextStyle(color: theme.textColor)),
          )).toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  final String typeFilter;
  final String? value;
  final Function(String?) onChanged;

  const _CategoryDropdown({
    required this.typeFilter,
    required this.value,
    required this.onChanged,
  });

  Map<String, String> _getAllCategories() {
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
  Widget build(BuildContext context) {
    final theme = AppTheme.instance;
    
    Map<String, String> categories;
    if (typeFilter == 'all') {
      categories = _getAllCategories();
    } else {
      categories = AppTheme.instance.getCategoriesByType(typeFilter);
      final sortedKeys = categories.keys.toList()
        ..sort((a, b) => categories[a]!.compareTo(categories[b]!));
      categories = {for (final k in sortedKeys) k: categories[k]!};
    }

    final items = <String, String>{'all': 'Все', ...categories};
    final currentValue = value ?? 'all';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.containsKey(currentValue) ? currentValue : 'all',
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: theme.textLightColor, size: 20),
          style: TextStyle(fontSize: 13, color: theme.textColor),
          dropdownColor: theme.surfaceColor,
          items: items.entries.map((e) => DropdownMenuItem(
            value: e.key,
            child: Text(e.value, style: TextStyle(color: theme.textColor)),
          )).toList(),
          onChanged: (v) => onChanged(v == 'all' ? null : v),
        ),
      ),
    );
  }
}

class _FilterSortHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String typeFilter;
  final String? categoryFilter;
  final SortField sortField;
  final SortOrder sortOrder;
  final Function(String) onTypeChanged;
  final Function(String?) onCategoryChanged;
  final Function(SortField) onToggleSort;
  final IconData Function(SortField) getSortIcon;

  _FilterSortHeaderDelegate({
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
  double get minExtent => 118;

  @override
  double get maxExtent => 118;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final theme = AppTheme.instance;
    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        border: Border(bottom: BorderSide(color: theme.borderColor)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _FilterDropdown(
                  label: 'Тип',
                  value: typeFilter,
                  items: const {'all': 'Все', 'care': 'Уход', 'decorative': 'Декор.'},
                  onChanged: onTypeChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CategoryDropdown(
                  typeFilter: typeFilter,
                  value: categoryFilter,
                  onChanged: onCategoryChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _SortChip(
                label: 'По сроку',
                icon: getSortIcon(SortField.expiry),
                isActive: sortField == SortField.expiry,
                onTap: () => onToggleSort(SortField.expiry),
              ),
              const SizedBox(width: 8),
              _SortChip(
                label: 'По названию',
                icon: getSortIcon(SortField.name),
                isActive: sortField == SortField.name,
                onTap: () => onToggleSort(SortField.name),
              ),
              const SizedBox(width: 8),
              _SortChip(
                label: 'По категории',
                icon: getSortIcon(SortField.category),
                isActive: sortField == SortField.category,
                onTap: () => onToggleSort(SortField.category),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _FilterSortHeaderDelegate oldDelegate) {
    // Always rebuild to catch theme changes
    return true;
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.instance;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? theme.primaryColor.withAlpha(25) : theme.backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? theme.primaryColor : theme.borderColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? theme.primaryColor : theme.textColor,
              ),
            ),
            const SizedBox(width: 3),
            Icon(icon, size: 12, color: isActive ? theme.primaryColor : theme.textLightColor),
          ],
        ),
      ),
    );
  }
}