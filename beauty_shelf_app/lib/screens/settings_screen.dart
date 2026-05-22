import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/storage_io.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _storage = MobileStorageService();
  bool _notificationsEnabled = false;
  int _notificationDays = 7;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    final service = NotificationService();
    final enabled = await service.areNotificationsEnabled();
    final days = await service.getNotificationDays();
    if (mounted) {
      setState(() {
        _notificationsEnabled = enabled;
        _notificationDays = days;
        _loading = false;
      });
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    final service = NotificationService();
    if (value && Platform.isAndroid) {
      final granted = await service.requestPermission();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Разрешите уведомления в настройках'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
    }
    await service.setNotificationsEnabled(value);
    setState(() => _notificationsEnabled = value);
  }

  Future<void> _setNotificationDays(int days) async {
    final service = NotificationService();
    await service.setNotificationDays(days);
    setState(() => _notificationDays = days);
  }

  Future<void> _exportData(BuildContext context) async {
    try {
      final result = await _storage.exportToJson();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result != null ? 'Экспорт завершён' : 'Ошибка экспорта'),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(left: 16, right: 16, top: 16),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка экспорта: $e'),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(left: 16, right: 16, top: 16),
          ),
        );
      }
    }
  }

  Future<void> _importData(BuildContext context) async {
    // Note: Import requires file picker which is implemented in platform-specific code
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Импорт временно недоступен на Android'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(left: 16, right: 16, top: 16),
        ),
      );
    }
  }

  static const _presets = [
    {'name': 'Розовый', 'primary': 0xFFE8B4BC, 'bg': 0xFFFDF9FA},
    {'name': 'Лаванда', 'primary': 0xFFB4A7E8, 'bg': 0xFFF5F3FA},
    {'name': 'Мята', 'primary': 0xFFA7E8C4, 'bg': 0xFFF3FAF5},
    {'name': 'Персик', 'primary': 0xFFE8C4A7, 'bg': 0xFFFAF5F3},
    {'name': 'Голубой', 'primary': 0xFFA7C4E8, 'bg': 0xFFF3F5FA},
    {'name': 'Монохром', 'primary': 0xFF666666, 'bg': 0xFFFAFAFA},
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppTheme.instance,
      builder: (context, _) {
        final theme = AppTheme.instance;
        
        return Scaffold(
          backgroundColor: theme.backgroundColor,
          appBar: AppBar(
            backgroundColor: theme.surfaceColor,
            title: Text('Настройки', style: TextStyle(color: theme.textColor)),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: theme.textColor),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: ListView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
            children: [
              // Dark mode toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.borderColor),
                ),
                child: Row(
                  children: [
                    Icon(
                      theme.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      color: theme.primaryColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Тёмная тема',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: theme.textColor,
                            ),
                          ),
                          Text(
                            theme.isDarkMode ? 'Включена' : 'Выключена',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.textLightColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: theme.isDarkMode,
                      onChanged: (_) => theme.toggleDarkMode(),
                      activeColor: theme.primaryColor,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Presets - horizontal scroll
              Text(
                'Цветовая тема',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: theme.textColor),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _presets.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final preset = _presets[index];
                    final primary = Color(preset['primary'] as int);
                    final bg = Color(preset['bg'] as int);
                    final isSelected = theme.primaryColor.value == primary.value;
                    
                    return _PresetChip(
                      name: preset['name'] as String,
                      primary: primary,
                      background: bg,
                      isSelected: isSelected,
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Custom colors
              Text(
                'Свой цвет',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: theme.textColor),
              ),
              const SizedBox(height: 12),
              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.borderColor),
                ),
                child: _CustomColorSection(),
              ),
              
              const SizedBox(height: 24),
              
              // Preview
              Text(
                'Превью',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: theme.textColor),
              ),
              const SizedBox(height: 12),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product card preview
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: theme.primaryColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.auto_awesome, color: theme.backgroundColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Сыворотка с витамином C',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: theme.textColor),
                              ),
                              Text(
                                'Уходовая • Сыворотка',
                                style: TextStyle(fontSize: 11, color: theme.textLightColor),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.neutralBgColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'OK · 120 дн.',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: theme.neutralColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Status badges row
                    Row(
                      children: [
                        _StatusBadge(label: 'OK', bgColor: theme.neutralBgColor, textColor: theme.neutralColor),
                        const SizedBox(width: 8),
                        _StatusBadge(label: 'Скоро', bgColor: theme.warningBgColor, textColor: theme.warningColor),
                        const SizedBox(width: 8),
                        _StatusBadge(label: 'Скоро', bgColor: theme.expiredBgColor, textColor: theme.expiredColor),
                        const SizedBox(width: 8),
                        _StatusBadge(label: 'Просрочено', bgColor: theme.expiredBgColor, textColor: theme.expiredColor),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),

              // Categories
              Text(
                'Категории',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: theme.textColor),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: theme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.borderColor),
                ),
                child: Column(
                  children: [
                    _CategoryTab(
                      type: 'care',
                      label: 'Уходовая',
                      categories: theme.getCategoriesByType('care'),
                    ),
                    const Divider(height: 1),
                    _CategoryTab(
                      type: 'decorative',
                      label: 'Декоративная',
                      categories: theme.getCategoriesByType('decorative'),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Notifications
              Text(
                'Уведомления',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: theme.textColor),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: theme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.borderColor),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.notifications, color: theme.primaryColor),
                      title: Text('Уведомления о сроке годности', style: TextStyle(color: theme.textColor)),
                      subtitle: Text(
                        _notificationsEnabled ? 'Включены' : 'Выключены',
                        style: TextStyle(color: theme.textLightColor, fontSize: 12),
                      ),
                      trailing: Switch(
                        value: _notificationsEnabled,
                        onChanged: _loading ? null : _toggleNotifications,
                        activeColor: theme.primaryColor,
                      ),
                    ),
                    if (_notificationsEnabled) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.timer, color: theme.primaryColor),
                        title: Text('Предупреждать за', style: TextStyle(color: theme.textColor)),
                        trailing: DropdownButton<int>(
                          value: _notificationDays,
                          underline: const SizedBox(),
                          items: [1, 3, 7, 14, 30].map((days) => DropdownMenuItem(
                            value: days,
                            child: Text('$days дн.'),
                          )).toList(),
                          onChanged: (value) {
                            if (value != null) _setNotificationDays(value);
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Export/Import
              Text(
                'Данные',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: theme.textColor),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: theme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.borderColor),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.upload_file, color: theme.primaryColor),
                      title: Text('Экспорт', style: TextStyle(color: theme.textColor)),
                      subtitle: Text('Сохранить продукты в JSON', style: TextStyle(color: theme.textLightColor, fontSize: 12)),
                      trailing: Icon(Icons.chevron_right, color: theme.textLightColor),
                      onTap: () => _exportData(context),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.download, color: theme.primaryColor),
                      title: Text('Импорт', style: TextStyle(color: theme.textColor)),
                      subtitle: Text('Загрузить продукты из JSON', style: TextStyle(color: theme.textLightColor, fontSize: 12)),
                      trailing: Icon(Icons.chevron_right, color: theme.textLightColor),
                      onTap: () => _importData(context),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // About
              Text(
                'О приложении',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: theme.textColor),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.borderColor),
                ),
                child: Row(
                  children: [
                    Icon(Icons.spa, color: theme.primaryColor, size: 32),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Полочка',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.textColor),
                        ),
                        Text(
                          'Версия 0.1',
                          style: TextStyle(fontSize: 14, color: theme.textLightColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CustomColorSection extends StatefulWidget {
  const _CustomColorSection();

  @override
  State<_CustomColorSection> createState() => _CustomColorSectionState();
}

class _CustomColorSectionState extends State<_CustomColorSection> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppTheme.instance,
      builder: (context, _) {
        final theme = AppTheme.instance;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TabBar(
              controller: _tabController,
              labelColor: theme.primaryColor,
              unselectedLabelColor: theme.textLightColor,
              indicatorColor: theme.primaryColor,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              tabs: const [
                Tab(text: 'Основной'),
                Tab(text: 'Фон'),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _ColorPickerColumn(
                    currentColor: theme.primaryColor,
                    onColorSelected: (color) {
                      AppTheme.instance.setCustomColors(color, theme.backgroundColor);
                    },
                  ),
                  _ColorPickerColumn(
                    currentColor: theme.backgroundColor,
                    onColorSelected: (color) {
                      AppTheme.instance.setCustomColors(theme.primaryColor, color);
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ColorPickerColumn extends StatelessWidget {
  const _ColorPickerColumn({
    required this.currentColor,
    required this.onColorSelected,
  });

  final Color currentColor;
  final ValueChanged<Color> onColorSelected;

  static const _palette = [
    0xFFE8B4BC, 0xFFE8A7B4, 0xFFD9848C, 0xFFE88C8C,
    0xFFB4A7E8, 0xFFA7B4E8, 0xFF9B8AD9, 0xFF8A7CC9,
    0xFFA7C4E8, 0xFFA7D4E8, 0xFF8FC9A3, 0xFF7CB98C,
    0xFFA7E8C4, 0xFFD4E8A7, 0xFFE8D4A7, 0xFFE8C4A7,
    0xFF666666, 0xFF888888, 0xFFAAAAAA, 0xFFCCCCCC,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.instance;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: currentColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: theme.borderColor),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _CompactHexInput(
                currentColor: currentColor,
                onColorChanged: onColorSelected,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _palette.map((colorValue) {
                final color = Color(colorValue);
                final isSelected = currentColor.value == color.value;
                
                return GestureDetector(
                  onTap: () => onColorSelected(color),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? theme.textColor : theme.borderColor,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _CompactHexInput extends StatefulWidget {
  const _CompactHexInput({required this.currentColor, required this.onColorChanged});

  final Color currentColor;
  final ValueChanged<Color> onColorChanged;

  @override
  State<_CompactHexInput> createState() => _CompactHexInputState();
}

class _CompactHexInputState extends State<_CompactHexInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _colorToHex(widget.currentColor));
  }

  @override
  void didUpdateWidget(_CompactHexInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentColor != widget.currentColor) {
      _controller.text = _colorToHex(widget.currentColor);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  Color? _hexToColor(String hex) {
    final cleaned = hex.replaceAll('#', '').toUpperCase();
    if (cleaned.length != 6) return null;
    final value = int.tryParse('FF$cleaned', radix: 16);
    return value != null ? Color(value) : null;
  }

  void _onChanged(String value) {
    final color = _hexToColor(value);
    if (color != null) {
      widget.onColorChanged(color);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.instance;
    
    return TextField(
      controller: _controller,
      onChanged: _onChanged,
      decoration: InputDecoration(
        hintText: '#E8B4BC',
        hintStyle: TextStyle(color: theme.textLightColor, fontSize: 12),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: theme.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: theme.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: theme.primaryColor, width: 2),
        ),
      ),
      style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: theme.textColor),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.name,
    required this.primary,
    required this.background,
    required this.isSelected,
  });

  final String name;
  final Color primary;
  final Color background;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.instance;
    final isDark = theme.isDarkMode;
    // In dark mode, use dark backgrounds for presets
    final displayBg = isDark ? const Color(0xFF2A2A2A) : background;
    final displayBorder = isDark ? theme.borderColor : theme.borderColor;
    
    return GestureDetector(
      onTap: () {
        theme.applyPreset(primary, background);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Применён: $name'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: isDark ? const Color(0xFF3A3A3A) : null,
            duration: const Duration(seconds: 1),
            margin: const EdgeInsets.only(left: 16, right: 16, top: 16),
          ),
        );
      },
      child: Container(
        width: 64,
        decoration: BoxDecoration(
          color: displayBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primary : displayBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: primary,
                shape: BoxShape.circle,
                border: Border.all(color: displayBg, width: 2),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: theme.textColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTab extends StatefulWidget {
  final String type;
  final String label;
  final Map<String, String> categories;

  const _CategoryTab({
    required this.type,
    required this.label,
    required this.categories,
  });

  @override
  State<_CategoryTab> createState() => _CategoryTabState();
}

class _CategoryTabState extends State<_CategoryTab> {
  bool _expanded = false;

  void _addCategory() {
    final keyController = TextEditingController();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Добавить категорию (${widget.label})'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: keyController,
              decoration: const InputDecoration(labelText: 'Ключ', hintText: 'my_category'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Название'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              if (keyController.text.isNotEmpty && nameController.text.isNotEmpty) {
                AppTheme.instance.addCategory(
                  widget.type,
                  keyController.text.trim().toLowerCase().replaceAll(' ', '_'),
                  nameController.text.trim(),
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.instance;
    final sortedKeys = widget.categories.keys.toList()..sort();

    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: theme.textLightColor,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.textColor,
                  ),
                ),
                const Spacer(),
                Text(
                  '${sortedKeys.length} шт.',
                  style: TextStyle(fontSize: 12, color: theme.textLightColor),
                ),
              ],
            ),
          ),
        ),
        if (_expanded) ...[
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorder: (oldIndex, newIndex) {
              if (newIndex > oldIndex) newIndex--;
              final keys = List<String>.from(sortedKeys);
              final key = keys.removeAt(oldIndex);
              keys.insert(newIndex, key);
              AppTheme.instance.reorderCategories(widget.type, keys);
            },
            children: sortedKeys.asMap().entries.map((entry) {
              final index = entry.key;
              final key = entry.value;
              final name = widget.categories[key]!;

              return ReorderableDragStartListener(
                key: ValueKey('${widget.type}_$key'),
                index: index,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      top: index > 0 ? BorderSide(color: theme.borderColor, width: 0.5) : BorderSide.none,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.drag_handle, size: 18, color: theme.textLightColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(name, style: TextStyle(color: theme.textColor)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        color: theme.expiredColor,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          AppTheme.instance.removeCategory(widget.type, key);
                        },
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: OutlinedButton.icon(
              onPressed: _addCategory,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Добавить'),
            ),
          ),
        ],
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;

  const _StatusBadge({
    required this.label,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: textColor),
      ),
    );
  }
}
