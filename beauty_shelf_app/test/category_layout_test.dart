import 'package:flutter_test/flutter_test.dart';
import 'package:polochka/utils/category_layout.dart';

CategoryRow h(String key) => CategoryRow.header(key);
CategoryRow l(String key) => CategoryRow.leaf(key);

void main() {
  group('layoutFromRows', () {
    test('groups leaves under the nearest preceding header', () {
      final layout = layoutFromRows([
        l('u1'),
        h('g1'), l('a'), l('b'),
        h('g2'), l('c'),
      ]);

      expect(layout.groupKeys, ['g1', 'g2']);
      expect(layout.leavesByGroup[''], ['u1']);
      expect(layout.leavesByGroup['g1'], ['a', 'b']);
      expect(layout.leavesByGroup['g2'], ['c']);
    });
  });

  group('reorderCategoryRows', () {
    test('moves a leaf into another group', () {
      final rows = [
        h('g1'), l('a'), l('b'),
        h('g2'), l('c'),
      ];

      final layout = layoutFromRows(reorderCategoryRows(rows, 2, 4));

      expect(layout.leavesByGroup['g1'], ['a']);
      expect(layout.leavesByGroup['g2'], ['b', 'c']);
    });

    test('moves a leaf above all groups (ungrouped)', () {
      final rows = [h('g1'), l('a'), l('b')];

      final layout = layoutFromRows(reorderCategoryRows(rows, 2, 0));

      expect(layout.leavesByGroup[''], ['b']);
      expect(layout.leavesByGroup['g1'], ['a']);
    });

    test('moving a header carries its leaves', () {
      final rows = [
        h('g1'), l('a'), l('b'),
        h('g2'), l('c'),
        h('g3'), l('d'),
      ];

      final layout = layoutFromRows(reorderCategoryRows(rows, 0, 5));

      expect(layout.groupKeys, ['g2', 'g1', 'g3']);
      expect(layout.leavesByGroup['g1'], ['a', 'b']);
      expect(layout.leavesByGroup['g2'], ['c']);
      expect(layout.leavesByGroup['g3'], ['d']);
    });

    test('moving a header snaps to a boundary and never splits a group', () {
      final rows = [
        h('g1'), l('a'), l('b'),
        h('g2'), l('c'), l('d'),
      ];

      // Drop into the middle of g2's leaves -> snap to a group boundary.
      final layout = layoutFromRows(reorderCategoryRows(rows, 0, 4));

      expect(layout.leavesByGroup['g2'], ['c', 'd']);
    });
  });
}
