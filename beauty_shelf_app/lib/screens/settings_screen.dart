import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onThemeChanged;

  const SettingsScreen({super.key, required this.onThemeChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _presets = [
    {
      'name': 'Розовый',
      'primary': 'E8B4BC',
      'primaryDark': 'D49BA5',
      'background': 'FDF9FA',
    },
    {
      'name': 'Лаванда',
      'primary': 'B4A7E8',
      'primaryDark': '9A87D4',
      'background': 'F5F3FA',
    },
    {
      'name': 'Мята',
      'primary': 'A7E8C4',
      'primaryDark': '87D4A5',
      'background': 'F3FAF5',
    },
    {
      'name': 'Персик',
      'primary': 'E8C4A7',
      'primaryDark': 'D4A987',
      'background': 'FAF5F3',
    },
    {
      'name': 'Голубой',
      'primary': 'A7C4E8',
      'primaryDark': '87A5D4',
      'background': 'F3F5FA',
    },
    {
      'name': 'Монохром',
      'primary': '666666',
      'primaryDark': '333333',
      'background': 'FAFAFA',
    },
  ];

  String _currentPreset = 'Розовый';

  void _applyPreset(Map<String, dynamic> preset) {
    setState(() {
      _currentPreset = preset['name'] ?? '';
      AppTheme.primaryColor = Color(int.parse('FF${preset['primary']}', radix: 16));
      AppTheme.primaryDarkColor = Color(int.parse('FF${preset['primaryDark']}', radix: 16));
      AppTheme.backgroundColor = Color(int.parse('FF${preset['background']}', radix: 16));
    });
    widget.onThemeChanged();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Применён: ${preset['name']}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Настройки', style: TextStyle(color: AppTheme.textColor)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Цветовая тема',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textColor),
          ),
          const SizedBox(height: 8),
          Text(
            'Выберите цветовую схему',
            style: TextStyle(fontSize: 14, color: AppTheme.textLightColor),
          ),
          const SizedBox(height: 16),
          
          // Compact horizontal scroll
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _presets.length,
              itemBuilder: (context, index) {
                final preset = _presets[index];
                final isSelected = _currentPreset == preset['name'];
                final color = Color(int.parse('FF${preset['primary']}', radix: 16));
                final bgColor = Color(int.parse('FF${preset['background']}', radix: 16));
                
                return GestureDetector(
                  onTap: () => _applyPreset(preset),
                  child: Container(
                    width: 90,
                    margin: EdgeInsets.only(right: index < _presets.length - 1 ? 12 : 0),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? color : AppTheme.borderColor,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          left: 8,
                          right: 8,
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? Icons.check_circle : Icons.circle_outlined,
                                color: isSelected ? color : AppTheme.textLightColor,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  preset['name'] ?? '',
                                  style: const TextStyle(fontSize: 11),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 32),
          
          Text(
            'Превью',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textColor),
          ),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
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
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Beauty Shelf',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textColor),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Тестовый продукт',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textColor),
                ),
                const SizedBox(height: 4),
                Text(
                  'Уходовая косметика',
                  style: TextStyle(fontSize: 12, color: AppTheme.textLightColor),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.okBgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'OK · 120 дн.',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.okColor),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {},
                    child: const Text('Добавить продукт'),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          Text(
            'О приложении',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textColor),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Beauty Shelf',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textColor),
                ),
                const SizedBox(height: 4),
                Text(
                  'Версия 1.0.0',
                  style: TextStyle(fontSize: 14, color: AppTheme.textLightColor),
                ),
                const SizedBox(height: 12),
                Text(
                  'Трекер косметики с отслеживанием сроков годности.',
                  style: TextStyle(fontSize: 14, color: AppTheme.textColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
