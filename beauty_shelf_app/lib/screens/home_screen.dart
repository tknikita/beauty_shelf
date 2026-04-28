import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../widgets/product_card.dart';
import '../widgets/product_table.dart';
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
  bool get _isTableView => AppTheme.instance.isTableView;

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

  void _toggleView() {
    AppTheme.instance.setTableView(!AppTheme.instance.isTableView);
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
        title: const Text('Удалить продукт?'),
        content: const Text('Это действие нельзя отменить.'),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
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

  Widget _buildCategoryChips() {
    final categories = AppTheme.instance.getCategoriesByType(_typeFilter);
    final sortedKeys = categories.keys.toList()
      ..sort((a, b) => categories[a]!.compareTo(categories[b]!));
    final theme = AppTheme.instance;

    return SizedBox(
      height: 28,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: sortedKeys.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _MiniFilterChip(
              label: 'Все',
              selected: _categoryFilter == null,
              onTap: () => _setCategoryFilter(null),
              color: theme.primaryColor,
            );
          }
          final key = sortedKeys[index - 1];
          return _MiniFilterChip(
            label: categories[key]!,
            selected: _categoryFilter == key,
            onTap: () => _setCategoryFilter(key),
            color: theme.primaryColor,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.instance.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.instance.surfaceColor,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppTheme.instance.primaryColor,
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
                color: AppTheme.instance.textColor,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppTheme.instance.backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.grid_view_rounded,
                    color: !_isTableView ? AppTheme.instance.primaryDarkColor : Colors.grey[400],
                    size: 20,
                  ),
                  onPressed: _toggleView,
                ),
                IconButton(
                  icon: Icon(
                    Icons.table_rows_rounded,
                    color: _isTableView ? AppTheme.instance.primaryDarkColor : Colors.grey[400],
                    size: 20,
                  ),
                  onPressed: _toggleView,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openSettings,
            color: Colors.grey[600],
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppTheme.instance.surfaceColor,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                // Expiring products banner
                _buildExpiringBanner(),
                const SizedBox(height: 8),
                TextField(
                  onChanged: (v) {
                    setState(() {
                      _searchQuery = v;
                      _applyFilters();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Поиск...',
                    prefixIcon: Icon(Icons.search, color: AppTheme.instance.textLightColor),
                    filled: true,
                    fillColor: AppTheme.instance.backgroundColor,
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
          Container(
            color: AppTheme.instance.surfaceColor,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _FilterChip(
                      label: 'Все',
                      selected: _typeFilter == 'all',
                      onTap: () => _setTypeFilter('all'),
                      color: AppTheme.instance.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Уход',
                      selected: _typeFilter == 'care',
                      onTap: () => _setTypeFilter('care'),
                      color: AppTheme.instance.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Декор.',
                      selected: _typeFilter == 'decorative',
                      onTap: () => _setTypeFilter('decorative'),
                      color: AppTheme.instance.primaryColor,
                    ),
                  ],
                ),
                if (_typeFilter != 'all') ...[
                  const SizedBox(height: 8),
                  _buildCategoryChips(),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildError()
                    : _filteredProducts.isEmpty
                        ? _buildEmpty()
                        : _isTableView
                            ? _buildTableView()
                            : _buildProductList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddModal,
        backgroundColor: AppTheme.instance.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('Не удалось загрузить', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _loadProducts,
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            _products.isEmpty ? 'Полка пуста' : 'Ничего не найдено',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            _products.isEmpty
                ? 'Нажмите + чтобы добавить первый продукт'
                : 'Попробуйте изменить фильтры',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildTableView() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ProductTable(
        products: _filteredProducts,
        onEdit: _showEditModal,
        onDelete: _confirmDelete,
      ),
    );
  }

  Widget _buildProductList() {
    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredProducts.length,
        itemBuilder: (context, index) {
          final product = _filteredProducts[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ProductCard(
              product: product,
              onEdit: () => _showEditModal(product),
              onDelete: () => _confirmDelete(product),
            ),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : AppTheme.instance.borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: selected ? Colors.white : AppTheme.instance.textColor,
          ),
        ),
      ),
    );
  }
}

class _MiniFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  const _MiniFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? color.withAlpha(30) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color : AppTheme.instance.borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selected ? color : AppTheme.instance.textLightColor,
            fontWeight: selected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
