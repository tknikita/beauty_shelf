import 'package:flutter_test/flutter_test.dart';
import 'package:polochka/models/product.dart';
import 'package:polochka/utils/sorting.dart';

/// Local midnight of "today" shifted by [days].
DateTime _dayOffset(int days) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day).add(Duration(days: days));
}

Product _p({
  String name = 'P',
  String type = 'care',
  String category = 'face_cream',
  DateTime? expiry,
  bool opened = false,
  DateTime? openedDate,
  int pao = 30,
  int? notificationDays,
  String? imageUrl,
}) {
  return Product(
    name: name,
    type: type,
    category: category,
    expiryDate: expiry ?? _dayOffset(100),
    isOpened: opened,
    openedDate: openedDate,
    expiryDaysAfterOpen: pao,
    notificationDays: notificationDays,
    imageUrl: imageUrl,
  );
}

void main() {
  group('effectiveExpiryDate', () {
    test('uses printed expiry when not opened', () {
      expect(_p(expiry: _dayOffset(50)).effectiveExpiryDate, _dayOffset(50));
    });

    test('uses opened date + PAO when opened', () {
      final p = _p(opened: true, openedDate: _dayOffset(-10), pao: 12, expiry: _dayOffset(500));
      expect(p.effectiveExpiryDate, _dayOffset(2));
    });

    test('falls back to printed expiry when opened without a date', () {
      final p = _p(opened: true, openedDate: null, expiry: _dayOffset(50));
      expect(p.effectiveExpiryDate, _dayOffset(50));
    });

    test('PAO overrides a far printed expiry (per SPEC)', () {
      final p = _p(opened: true, openedDate: _dayOffset(-3), pao: 5, expiry: _dayOffset(365));
      expect(p.effectiveExpiryDate, _dayOffset(2));
      expect(p.daysLeft, 2);
    });
  });

  group('daysLeft', () {
    test('positive for future date', () => expect(_p(expiry: _dayOffset(10)).daysLeft, 10));
    test('zero for today', () => expect(_p(expiry: _dayOffset(0)).daysLeft, 0));
    test('negative for past date', () => expect(_p(expiry: _dayOffset(-1)).daysLeft, -1));
    test('opened product counts down from PAO', () {
      final p = _p(opened: true, openedDate: _dayOffset(-5), pao: 5, expiry: _dayOffset(365));
      expect(p.daysLeft, 0);
    });
    test('opened product ignores a nearer printed expiry', () {
      // Printed expiry is 1 day away, but PAO gives 9 more days -> 9.
      final p = _p(opened: true, openedDate: _dayOffset(-1), pao: 10, expiry: _dayOffset(1));
      expect(p.daysLeft, 9);
    });
  });

  group('status', () {
    test('expired when daysLeft < 0', () {
      expect(_p(expiry: _dayOffset(-1)).status, ProductStatus.expired);
    });
    test('danger at 0 and 29', () {
      expect(_p(expiry: _dayOffset(0)).status, ProductStatus.danger);
      expect(_p(expiry: _dayOffset(29)).status, ProductStatus.danger);
    });
    test('warning at 30 and 59', () {
      expect(_p(expiry: _dayOffset(30)).status, ProductStatus.warning);
      expect(_p(expiry: _dayOffset(59)).status, ProductStatus.warning);
    });
    test('ok at 60 and beyond', () {
      expect(_p(expiry: _dayOffset(60)).status, ProductStatus.ok);
      expect(_p(expiry: _dayOffset(365)).status, ProductStatus.ok);
    });
  });

  group('serialization', () {
    test('fromJson maps is_opened, dates and notification days', () {
      final p = Product.fromJson({
        'id': 5,
        'name': 'X',
        'type': 'care',
        'category': 'serum',
        'purpose': 'Y',
        'expiry_date': '2026-01-02',
        'is_opened': 1,
        'opened_date': '2025-12-01',
        'expiry_days_after_open': 90,
        'image_url': '/api/images/a.png',
        'notification_days': 14,
      });
      expect(p.id, 5);
      expect(p.isOpened, isTrue);
      expect(p.openedDate, DateTime(2025, 12, 1));
      expect(p.expiryDaysAfterOpen, 90);
      expect(p.notificationDays, 14);
      expect(p.imageUrl, '/api/images/a.png');
    });

    test('fromJson handles closed product without optional fields', () {
      final p = Product.fromJson({
        'name': 'X',
        'type': 'care',
        'category': 'serum',
        'expiry_date': '2026-01-02',
        'is_opened': 0,
      });
      expect(p.isOpened, isFalse);
      expect(p.openedDate, isNull);
      expect(p.notificationDays, isNull);
      expect(p.expiryDaysAfterOpen, 30);
    });

    test('toJson omits id when null and formats dates', () {
      final json = _p(name: 'X', expiry: DateTime(2026, 1, 2)).toJson();
      expect(json.containsKey('id'), isFalse);
      expect(json['expiry_date'], '2026-01-02');
      expect(json['is_opened'], 0);
    });

    test('toMap round-trips notification days', () {
      final map = _p(notificationDays: 21).toMap();
      expect(map['notification_days'], 21);
      expect(Product.fromMap(map).notificationDays, 21);
    });

    test('quantity defaults to 1 and round-trips', () {
      final base = Product(
        name: 'X',
        type: 'care',
        category: 'cream',
        expiryDate: DateTime(2027, 1, 1),
      );
      expect(base.quantity, 1);

      final p = base.copyWith(quantity: 3);
      expect(p.quantity, 3);
      expect(p.toJson()['quantity'], 3);
      expect(p.toMap()['quantity'], 3);
      expect(Product.fromJson(p.toJson()).quantity, 3);
      expect(Product.fromMap(p.toMap()).quantity, 3);
    });
  });

  group('copyWith', () {
    test('keeps existing values', () {
      final c = _p(name: 'A', notificationDays: 7, imageUrl: 'u').copyWith(name: 'B');
      expect(c.name, 'B');
      expect(c.notificationDays, 7);
      expect(c.imageUrl, 'u');
    });

    test('can clear nullable fields explicitly', () {
      final p = _p(notificationDays: 7, imageUrl: 'u', opened: true, openedDate: _dayOffset(-1));
      final c = p.copyWith(
        clearNotificationDays: true,
        clearImageUrl: true,
        clearOpenedDate: true,
      );
      expect(c.notificationDays, isNull);
      expect(c.imageUrl, isNull);
      expect(c.openedDate, isNull);
    });
  });

  group('image url helpers', () {
    test('isLocalPath distinguishes local files from remote/api/web', () {
      expect(Product.isLocalPath(''), isFalse);
      expect(Product.isLocalPath('https://x/a.png'), isFalse);
      expect(Product.isLocalPath('http://x/a.png'), isFalse);
      expect(Product.isLocalPath('/api/images/a.png'), isFalse);
      expect(Product.isLocalPath('/images/a.png'), isFalse);
      expect(Product.isLocalPath('blob:http://x/y'), isFalse);
      expect(Product.isLocalPath('data:image/png;base64,AAA'), isFalse);
      expect(Product.isLocalPath('/data/user/0/app/images/a.png'), isTrue);
      expect(Product.isLocalPath('/var/mobile/Containers/.../a.png'), isTrue);
    });

    test('getDisplayUrl prefixes /api for backend-relative images', () {
      expect(Product.getDisplayUrl(null), isNull);
      expect(Product.getDisplayUrl('/images/a.png'), '/api/images/a.png');
      expect(Product.getDisplayUrl('/api/images/a.png'), '/api/images/a.png');
      expect(Product.getDisplayUrl('https://x/a.png'), 'https://x/a.png');
    });

    test('effectiveImageUrl normalizes stored value', () {
      expect(_p(imageUrl: '/images/a.png').effectiveImageUrl, '/api/images/a.png');
      expect(_p(imageUrl: '/api/images/a.png').effectiveImageUrl, '/api/images/a.png');
      expect(_p(imageUrl: '/data/x/a.png').effectiveImageUrl, '/data/x/a.png');
      expect(_p(imageUrl: 'https://x/a.png').effectiveImageUrl, 'https://x/a.png');
    });
  });

  group('sorting', () {
    test('by name ascending and descending', () {
      final list = [_p(name: 'b'), _p(name: 'a'), _p(name: 'c')];
      expect(sortProducts(list, SortField.name, SortOrder.asc).map((e) => e.name), ['a', 'b', 'c']);
      expect(sortProducts(list, SortField.name, SortOrder.desc).map((e) => e.name), ['c', 'b', 'a']);
    });

    test('by expiry uses effective daysLeft', () {
      final list = [
        _p(name: 'far', expiry: _dayOffset(100)),
        _p(name: 'near', expiry: _dayOffset(1)),
      ];
      expect(sortProducts(list, SortField.expiry, SortOrder.asc).first.name, 'near');
    });

    test('by category sorts by localized name', () {
      final list = [_p(name: 'a', category: 'serum'), _p(name: 'b', category: 'blush')];
      final sorted = sortProducts(list, SortField.category, SortOrder.asc);
      final names = sorted
          .map((p) => Categories.getCategoryName(p.type, p.category).toLowerCase())
          .toList();
      final expected = List<String>.from(names)..sort();
      expect(names, expected);
    });
  });

  group('Categories', () {
    test('resolves known keys and falls back to the raw key', () {
      expect(Categories.getCategoryName('care', 'serum'), 'Сыворотка');
      expect(Categories.getCategoryName('care', 'unknown_key'), 'unknown_key');
    });
  });
}
