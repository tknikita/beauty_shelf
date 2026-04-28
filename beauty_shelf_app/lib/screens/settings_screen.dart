import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
            backgroundColor: Colors.white,
            title: Text('Настройки', style: TextStyle(color: theme.textColor)),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: theme.textColor),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
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
                  color: Colors.white,
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Beauty Shelf',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.textColor),
                          ),
                          Text(
                            'Тестовый продукт • OK · 120 дн.',
                            style: TextStyle(fontSize: 12, color: theme.textLightColor),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.okBgColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'OK',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: theme.okColor),
                      ),
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
                  color: Colors.white,
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
                          'Beauty Shelf',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.textColor),
                        ),
                        Text(
                          'Версия 1.0.0',
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
    
    return GestureDetector(
      onTap: () {
        theme.applyPreset(primary, background);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Применён: $name'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        width: 64,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primary : theme.borderColor,
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
                border: Border.all(color: background, width: 2),
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
