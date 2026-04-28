import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
              Text(
                'Цветовая тема',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: theme.textColor),
              ),
              const SizedBox(height: 8),
              Text(
                'Выберите цветовую схему',
                style: TextStyle(fontSize: 14, color: theme.textLightColor),
              ),
              const SizedBox(height: 16),
              
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _PresetCard(name: 'Розовый', primary: const Color(0xFFE8B4BC), background: const Color(0xFFFDF9FA)),
                  _PresetCard(name: 'Лаванда', primary: const Color(0xFFB4A7E8), background: const Color(0xFFF5F3FA)),
                  _PresetCard(name: 'Мята', primary: const Color(0xFFA7E8C4), background: const Color(0xFFF3FAF5)),
                  _PresetCard(name: 'Персик', primary: const Color(0xFFE8C4A7), background: const Color(0xFFFAF5F3)),
                  _PresetCard(name: 'Голубой', primary: const Color(0xFFA7C4E8), background: const Color(0xFFF3F5FA)),
                  _PresetCard(name: 'Монохром', primary: const Color(0xFF666666), background: const Color(0xFFFAFAFA)),
                ],
              ),
              
              const SizedBox(height: 32),
              
              Text(
                'Свой цвет',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: theme.textColor),
              ),
              const SizedBox(height: 8),
              Text(
                'Введите HEX-код цвета',
                style: TextStyle(fontSize: 14, color: theme.textLightColor),
              ),
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.borderColor),
                ),
                child: Column(
                  children: [
                    _HexColorInput(
                      label: 'Основной цвет',
                      currentColor: theme.primaryColor,
                      onColorChanged: (color) {
                        if (color != null) {
                          AppTheme.instance.setCustomColors(color, theme.backgroundColor);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    _HexColorInput(
                      label: 'Цвет фона',
                      currentColor: theme.backgroundColor,
                      onColorChanged: (color) {
                        if (color != null) {
                          AppTheme.instance.setCustomColors(theme.primaryColor, color);
                        }
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              Text(
                'Превью',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: theme.textColor),
              ),
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                        Text(
                          'Beauty Shelf',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: theme.textColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Тестовый продукт',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.textColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Уходовая косметика',
                      style: TextStyle(fontSize: 12, color: theme.textLightColor),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.okBgColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'OK · 120 дн.',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: theme.okColor),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              Text(
                'О приложении',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: theme.textColor),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Beauty Shelf',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.textColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Версия 1.0.0',
                      style: TextStyle(fontSize: 14, color: theme.textLightColor),
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
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: theme.textColor),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color ?? widget.currentColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.borderColor),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _controller,
                onChanged: _onChanged,
                decoration: InputDecoration(
                  hintText: '#E8B4BC',
                  hintStyle: TextStyle(color: theme.textLightColor),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: _isValid ? theme.borderColor : theme.dangerColor,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: _isValid ? theme.primaryColor : theme.dangerColor,
                      width: 2,
                    ),
                  ),
                  errorText: _isValid ? null : 'Неверный формат',
                ),
                style: TextStyle(fontFamily: 'monospace', fontSize: 14, color: theme.textColor),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PresetCard extends StatelessWidget {
  final String name;
  final Color primary;
  final Color background;

  const _PresetCard({
    required this.name,
    required this.primary,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.instance;
    final isSelected = theme.primaryColor.value == primary.value;

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
        width: 100,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primary : theme.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              height: 30,
              decoration: BoxDecoration(
                color: primary,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: theme.textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
