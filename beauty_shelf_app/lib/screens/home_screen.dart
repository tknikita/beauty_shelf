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
  
  String _filter = 'all';
  String _searchQuery = '';
  bool _isTableView = false;

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
        // Type filter
        if (_filter != 'all' && p.type != _filter) return false;
        // Search filter
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

  void _setFilter(String filter) {
    setState(() {
      _filter = filter;
      _applyFilters();
    });
  }

  void _toggleView() {
    setState(() {
      _isTableView = !_isTableView;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.instance.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
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
          // View toggle
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
          // Search
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: TextField(
              onChanged: (v) => _applyFilters(),
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
          ),

          // Filters
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Все',
                  selected: _filter == 'all',
                  onTap: () => _setFilter('all'),
                  color: AppTheme.instance.primaryColor,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Уход',
                  selected: _filter == 'care',
                  onTap: () => _setFilter('care'),
                  color: AppTheme.instance.primaryColor,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Декоративная',
                  selected: _filter == 'decorative',
                  onTap: () => _setFilter('decorative'),
                  color: AppTheme.instance.primaryColor,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Content
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
    return Padding(
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
