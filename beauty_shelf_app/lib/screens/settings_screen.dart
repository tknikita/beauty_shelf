import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/backup_service.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final BackupService _backup = BackupService();
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
    if (value && defaultTargetPlatform == TargetPlatform.android) {
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

  Future<void> _createBackup(BuildContext context) async {
    try {
      final path = await _backup.exportBackup();
      if (context.mounted) {
        _showMessage(
          context,
          path != null ? 'Резервная копия сохранена' : 'Сохранение отменено',
        );
      }
    } catch (e) {
      if (context.mounted) _showMessage(context, 'Ошибка резервного копирования: $e');
    }
  }

  Future<void> _restoreBackup(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Восстановить из копии?'),
        content: const Text(
          'Все текущие товары будут заменены данными из резервной копии.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Восстановить'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final count = await _backup.restoreBackup();
      if (!context.mounted) return;
      _showMessage(
        context,
        count < 0 ? 'Восстановление отменено' : 'Восстановлено товаров: $count',
      );
    } catch (e) {
      if (context.mounted) _showMessage(context, 'Ошибка восстановления: $e');
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(left: 16, right: 16, top: 16),
      ),
    );
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
                        activeThumbColor: theme.primaryColor,
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
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final preset = _presets[index];
                    final primary = Color(preset['primary'] as int);
                    final bg = Color(preset['bg'] as int);
                    final isSelected =
                        theme.primaryColor.toARGB32() == primary.toARGB32();
                    
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
                    _CategoryTab(type: 'care', label: 'Уходовая'),
                    const Divider(height: 1),
                    _CategoryTab(type: 'decorative', label: 'Декоративная'),
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
                      activeThumbColor: theme.primaryColor,
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
                      leading: Icon(Icons.backup_outlined, color: theme.primaryColor),
                      title: Text('Создать резервную копию', style: TextStyle(color: theme.textColor)),
                      subtitle: Text('Товары, категории, настройки и фото в ZIP', style: TextStyle(color: theme.textLightColor, fontSize: 12)),
                      trailing: Icon(Icons.chevron_right, color: theme.textLightColor),
                      onTap: () => _createBackup(context),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.restore, color: theme.primaryColor),
                      title: Text('Восстановить', style: TextStyle(color: theme.textColor)),
                      subtitle: Text('Заменить данные из ZIP-копии', style: TextStyle(color: theme.textLightColor, fontSize: 12)),
                      trailing: Icon(Icons.chevron_right, color: theme.textLightColor),
                      onTap: () => _restoreBackup(context),
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
                final isSelected =
                    currentColor.toARGB32() == color.toARGB32();
                
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
    return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
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

  const _CategoryTab({required this.type, required this.label});

  @override
  State<_CategoryTab> createState() => _CategoryTabState();
}

class _CategoryTabState extends State<_CategoryTab> {
  bool _expanded = false;
  // Groups start expanded; this tracks the ones the user collapsed.
  final Set<String> _collapsed = {};

  static const _ungroupedId = '__ungrouped__';

  String _newKey() => 'custom_${DateTime.now().microsecondsSinceEpoch}';

  bool _isExpandedGroup(String id) => !_collapsed.contains(id);

  Future<void> _addCategory(String? groupKey) async {
    final nameController = TextEditingController();
    final groups = AppTheme.instance.getGroupsByType(widget.type);
    String? selectedGroup = groupKey;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('Добавить категорию · ${widget.label}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Название'),
              ),
              const SizedBox(height: 12),
              DropdownButton<String>(
                isExpanded: true,
                value: selectedGroup ?? '',
                items: [
                  const DropdownMenuItem(value: '', child: Text('— без раздела —')),
                  ...groups.entries.map(
                    (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                  ),
                ],
                onChanged: (v) => setLocal(
                  () => selectedGroup = (v == null || v.isEmpty) ? null : v,
                ),
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
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                AppTheme.instance.addCategory(
                  widget.type,
                  _newKey(),
                  name,
                  groupKey: selectedGroup,
                );
                Navigator.pop(ctx);
              },
              child: const Text('Добавить'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addGroup() async {
    final nameController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Новый раздел · ${widget.label}'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Название раздела'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              AppTheme.instance.addGroup(widget.type, _newKey(), name);
              Navigator.pop(ctx);
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeGroup(String key, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Удалить раздел «$name»?'),
        content: const Text('Категории из него останутся, но станут без раздела.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (ok == true) AppTheme.instance.removeGroup(widget.type, key);
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.instance;
    final tree = AppTheme.instance.getCategoryTree(widget.type);
    final total = tree.fold<int>(0, (sum, g) => sum + g.leaves.length);

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
                  '$total шт.',
                  style: TextStyle(fontSize: 12, color: theme.textLightColor),
                ),
              ],
            ),
          ),
        ),
        if (_expanded) ...[
          for (final group in tree) ..._buildGroup(theme, group),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _addCategory(null),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Категория'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _addGroup,
                    icon: const Icon(Icons.create_new_folder_outlined, size: 18),
                    label: const Text('Раздел'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildGroup(AppTheme theme, CategoryGroup group) {
    final isUngrouped = group.isUngrouped;
    final id = group.key ?? _ungroupedId;
    final expanded = isUngrouped || _isExpandedGroup(id);
    final deletable =
        !isUngrouped && !AppTheme.instance.isDefaultGroup(widget.type, group.key!);
    final indent = isUngrouped ? 20.0 : 40.0;

    return [
      if (!isUngrouped)
        InkWell(
          onTap: () => setState(() {
            if (_collapsed.contains(id)) {
              _collapsed.remove(id);
            } else {
              _collapsed.add(id);
            }
          }),
          child: Container(
            color: theme.neutralBgColor,
            padding: const EdgeInsets.only(left: 8, right: 4),
            child: Row(
              children: [
                Icon(
                  expanded ? Icons.arrow_drop_down : Icons.arrow_right,
                  size: 22,
                  color: theme.textLightColor,
                ),
                Expanded(
                  child: Text(
                    group.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: theme.textColor,
                    ),
                  ),
                ),
                Text(
                  '${group.leaves.length}',
                  style: TextStyle(fontSize: 12, color: theme.textLightColor),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  color: theme.primaryColor,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                  tooltip: 'Добавить в раздел',
                  onPressed: () => _addCategory(group.key),
                ),
                if (deletable)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    color: theme.expiredColor,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                    onPressed: () => _removeGroup(group.key!, group.name),
                  ),
              ],
            ),
          ),
        ),
      if (expanded)
        for (final leaf in group.leaves.entries)
          _buildLeaf(theme, leaf.key, leaf.value, indent),
    ];
  }

  Widget _buildLeaf(AppTheme theme, String key, String name, double indent) {
    return Container(
      key: ValueKey('leaf_${widget.type}_$key'),
      padding: EdgeInsets.fromLTRB(indent, 6, 12, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(name, style: TextStyle(color: theme.textColor)),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            color: theme.expiredColor,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
            onPressed: () => AppTheme.instance.removeCategory(widget.type, key),
          ),
        ],
      ),
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
