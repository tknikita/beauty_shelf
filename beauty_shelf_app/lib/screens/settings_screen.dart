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
      'name': 'Розовый (по умолчанию)',
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

  String _currentPreset = 'Розовый (по умолчанию)';

  void _applyPreset(Map<String, dynamic> preset) {
    setState(() {
      _currentPreset = preset['name'];
      AppTheme.primaryColor = Color(int.parse('FF${preset['primary']}', radix: 16));
      AppTheme.primaryDarkColor = Color(int.parse('FF${preset['primaryDark']}', radix: 16));
      AppTheme.backgroundColor = Color(int.parse('FF${preset['background']}', radix: 16));
    });
    widget.onThemeChanged();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Применён пресет: ${preset['name']}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Настройки'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Color theme section
          const Text(
            'Цветовая тема',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Выберите цветовую схему приложения',
            style: TextStyle(fontSize: 14, color: Color(0xFF8A8A8A)),
          ),
          const SizedBox(height: 16),
          
          // Presets grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _presets.length,
            itemBuilder: (context, index) {
              final preset = _presets[index];
              final isSelected = _currentPreset == preset['name'];
              final color = Color(int.parse('FF${preset['primary']}', radix: 16));
              
              return GestureDetector(
                onTap: () => _applyPreset(preset),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? color : const Color(0xFFE8E8E8),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        left: 12,
                        right: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isSelected)
                              Icon(Icons.check_circle, color: color, size: 20),
                            if (!isSelected)
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFE8E8E8)),
                                ),
                              ),
                            const SizedBox(height: 8),
                            Text(
                              preset['name'] ?? '',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
          
          const SizedBox(height: 32),
          
          // Preview section
          const Text(
            'Превью',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          
          // Sample card preview
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8E8E8)),
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
                    const Expanded(
                      child: Text(
                        'Beauty Shelf',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Тестовый продукт',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Уходовая косметика',
                  style: TextStyle(fontSize: 12, color: Color(0xFF8A8A8A)),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F7F2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'OK · 120 дн.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF5A9E6F),
                    ),
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
          
          // About section
          const Text(
            'О приложении',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8E8E8)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Beauty Shelf',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4),
                Text(
                  'Версия 1.0.0',
                  style: TextStyle(fontSize: 14, color: Color(0xFF8A8A8A)),
                ),
                SizedBox(height: 12),
                Text(
                  'Трекер косметики с отслеживанием сроков годности.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
