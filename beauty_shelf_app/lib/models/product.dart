class Product {
  final int? id;
  final String name;
  final String type;
  final String category;
  final String? purpose;
  final DateTime expiryDate;
  final bool isOpened;
  final DateTime? openedDate;
  final int expiryDaysAfterOpen;

  Product({
    this.id,
    required this.name,
    required this.type,
    required this.category,
    this.purpose,
    required this.expiryDate,
    this.isOpened = false,
    this.openedDate,
    this.expiryDaysAfterOpen = 30,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int?,
      name: json['name'] as String,
      type: json['type'] as String,
      category: json['category'] as String,
      purpose: json['purpose'] as String?,
      expiryDate: DateTime.parse(json['expiry_date'] as String),
      isOpened: (json['is_opened'] as int?) == 1,
      openedDate: json['opened_date'] != null
          ? DateTime.parse(json['opened_date'] as String)
          : null,
      expiryDaysAfterOpen: json['expiry_days_after_open'] as int? ?? 30,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'type': type,
      'category': category,
      'purpose': purpose,
      'expiry_date': expiryDate.toIso8601String().split('T')[0],
      'is_opened': isOpened ? 1 : 0,
      'opened_date': openedDate?.toIso8601String().split('T')[0],
      'expiry_days_after_open': expiryDaysAfterOpen,
    };
  }

  DateTime get effectiveExpiryDate {
    if (isOpened && openedDate != null) {
      return openedDate!.add(Duration(days: expiryDaysAfterOpen));
    }
    return expiryDate;
  }

  int get daysLeft {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(
      effectiveExpiryDate.year,
      effectiveExpiryDate.month,
      effectiveExpiryDate.day,
    );
    return expiry.difference(today).inDays;
  }

  ProductStatus get status {
    final days = daysLeft;
    if (days < 0) return ProductStatus.expired;
    if (days < 30) return ProductStatus.danger;
    if (days < 60) return ProductStatus.warning;
    return ProductStatus.ok;
  }

  Product copyWith({
    int? id,
    String? name,
    String? type,
    String? category,
    String? purpose,
    DateTime? expiryDate,
    bool? isOpened,
    DateTime? openedDate,
    int? expiryDaysAfterOpen,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      category: category ?? this.category,
      purpose: purpose ?? this.purpose,
      expiryDate: expiryDate ?? this.expiryDate,
      isOpened: isOpened ?? this.isOpened,
      openedDate: openedDate ?? this.openedDate,
      expiryDaysAfterOpen: expiryDaysAfterOpen ?? this.expiryDaysAfterOpen,
    );
  }
}

enum ProductStatus { ok, warning, danger, expired }

class Categories {
  static const Map<String, Map<String, String>> byType = {
    'care': {
      'basic_care': 'Базовая уходовая',
      'cleanser': 'Очищение',
      'tonic': 'Тоник',
      'serum': 'Сыворотка',
      'cream': 'Крем',
      'face_cream': 'Крем для лица',
      'eye_cream': 'Крем для глаз',
      'mask': 'Маска',
      'sunscreen': 'Солнцезащита',
      'special': 'Специальный уход',
    },
    'decorative': {
      'base': 'База',
      'tone': 'Тональное средство',
      'concealer': 'Консилер',
      'powder': 'Пудра',
      'blush': 'Румяна',
      'bronzer': 'Бронзер',
      'highlighter': 'Хайлайтер',
      'eyeshadow': 'Тени для век',
      'eyeliner': 'Подводка',
      'mascara': 'Тушь',
      'eyebrows': 'Брови',
      'lips': 'Губы',
      'nails': 'Ногти',
    },
  };

  static String getCategoryName(String type, String category) {
    return byType[type]?[category] ?? category;
  }
}
