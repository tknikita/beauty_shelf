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
              
              // Custom colors - compact
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
                child: Row(
                  children: [
                    Expanded(
                      child: _HexColorInput(
                        label: 'Основной',
                        currentColor: theme.primaryColor,
                        onColorChanged: (color) {
                          if (color != null) {
                            AppTheme.instance.setCustomColors(color, theme.backgroundColor);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _HexColorInput(
                        label: 'Фон',
                        currentColor: theme.backgroundColor,
                        onColorChanged: (color) {
                          if (color != null) {
                            AppTheme.instance.setCustomColors(theme.primaryColor, color);
                          }
                        },
                      ),
                    ),
                  ],
                ),
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

class _HexColorInput extends StatefulWidget {
  const _HexColorInput({required this.label, required this.currentColor, required this.onColorChanged});

  final String label;
  final Color currentColor;
  final ValueChanged<Color?> onColorChanged;

  @override
  State<_HexColorInput> createState() => _HexColorInputState();
}

class _HexColorInputState extends State<_HexColorInput> {
  late TextEditingController _controller;
  bool _isValid = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _colorToHex(widget.currentColor));
  }

  @override
  void didUpdateWidget(_HexColorInput oldWidget) {
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
    setState(() {
      _isValid = color != null || value.isEmpty;
    });
    widget.onColorChanged(color);
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.instance;
    final color = _hexToColor(_controller.text);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: theme.textColor),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color ?? widget.currentColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: theme.borderColor),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
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
                    borderSide: BorderSide(
                      color: _isValid ? theme.borderColor : theme.dangerColor,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: _isValid ? theme.primaryColor : theme.dangerColor,
                      width: 2,
                    ),
                  ),
                  errorText: _isValid ? null : '!',
                  errorStyle: const TextStyle(fontSize: 0, height: 0),
                ),
                style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: theme.textColor),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
