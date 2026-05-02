import '../theme/app_theme.dart';

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
  final String? imageUrl;

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
    this.imageUrl,
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
      imageUrl: json['image_url'] as String?,
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
      'image_url': imageUrl,
    };
  }

  // SQLite map support
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: map['type'] as String,
      category: map['category'] as String,
      purpose: map['purpose'] as String?,
      expiryDate: DateTime.parse(map['expiry_date'] as String),
      isOpened: (map['is_opened'] as int?) == 1,
      openedDate: map['opened_date'] != null
          ? DateTime.parse(map['opened_date'] as String)
          : null,
      expiryDaysAfterOpen: map['expiry_days_after_open'] as int? ?? 30,
      imageUrl: map['image_url'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
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
      'image_url': imageUrl,
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

  String? get effectiveImageUrl {
    if (imageUrl == null) return null;
    // Local file path - return as is
    if (isLocalImage) return imageUrl;
    // URL already includes /api prefix from backend
    // Only add /api if URL starts with /images/ (without /api)
    if (imageUrl!.startsWith('/images/')) {
      return '/api$imageUrl';
    }
    return imageUrl;
  }

  /// Helper to convert image URL for display
  static String? getDisplayUrl(String? url) {
    if (url == null) return null;
    // Local file path - return as is
    if (isLocalPath(url)) return url;
    // URL already includes /api prefix from backend
    if (url.startsWith('/images/')) {
      return '/api$url';
    }
    return url;
  }

  /// Check if path is a local file path (not a remote URL)
  static bool isLocalPath(String path) {
    return path.startsWith('/data/') ||
           path.startsWith('/storage/') ||
           path.startsWith('data/');
  }

  /// Check if imageUrl is a local file path (not a remote URL)
  bool get isLocalImage {
    if (imageUrl == null) return false;
    return isLocalPath(imageUrl!);
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
    String? imageUrl,
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
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

enum ProductStatus { ok, warning, danger, expired }

/// Categories helper - uses AppTheme for actual data
class Categories {
  static Map<String, Map<String, String>> get byType => AppTheme.instance.categories;
  static String getCategoryName(String type, String category) => byType[type]?[category] ?? category;
}
