/// Row model and reordering logic for the flat manual category editor.
///
/// The editor is a single flat, drag-reorderable list mixing group headers and
/// leaves. Dragging a header moves the header together with its leaves, and
/// headers snap to group boundaries so a drag never splits another group.
library;

class CategoryRow {
  final String? groupKey;
  final String? leafKey;

  const CategoryRow.header(this.groupKey) : leafKey = null;
  const CategoryRow.leaf(this.leafKey) : groupKey = null;

  bool get isHeader => leafKey == null;
}

/// Group order plus per-group leaf order derived from flat rows. Leaves before
/// the first header belong to the un-grouped bucket (`''`).
class CategoryLayout {
  final List<String> groupKeys;
  final Map<String, List<String>> leavesByGroup;

  const CategoryLayout(this.groupKeys, this.leavesByGroup);
}

CategoryLayout layoutFromRows(List<CategoryRow> rows) {
  final groupKeys = <String>[];
  final leavesByGroup = <String, List<String>>{};
  String? current;
  for (final row in rows) {
    if (row.isHeader) {
      current = row.groupKey;
      groupKeys.add(row.groupKey!);
      leavesByGroup.putIfAbsent(row.groupKey!, () => []);
    } else {
      final g = current ?? '';
      leavesByGroup.putIfAbsent(g, () => []).add(row.leafKey!);
    }
  }
  return CategoryLayout(groupKeys, leavesByGroup);
}

/// Returns [rows] with the item at [oldIndex] moved to [newIndex] (indices use
/// the ReorderableListView convention). A header carries its trailing leaves.
List<CategoryRow> reorderCategoryRows(
  List<CategoryRow> rows,
  int oldIndex,
  int newIndex,
) {
  final working = List<CategoryRow>.of(rows);
  final moved = working[oldIndex];

  if (moved.isHeader) {
    var end = oldIndex + 1;
    while (end < working.length && !working[end].isHeader) {
      end++;
    }
    final block = working.sublist(oldIndex, end);
    working.removeRange(oldIndex, end);

    // newIndex is in the original list's coordinates; after removing the whole
    // block shift it back by the block length when moving down.
    var target = newIndex;
    if (newIndex > oldIndex) target -= block.length;
    target = _snapToGroupBoundary(working, target);

    working.insertAll(target, block);
  } else {
    if (newIndex > oldIndex) newIndex--;
    final item = working.removeAt(oldIndex);
    working.insert(newIndex.clamp(0, working.length), item);
  }
  return working;
}

/// Nearest position where a whole group can start (0 or right after another
/// group's block), so dragging a header never splits a group.
int _snapToGroupBoundary(List<CategoryRow> rows, int target) {
  final boundaries = <int>[0];
  var i = 0;
  while (i < rows.length) {
    if (rows[i].isHeader) {
      var e = i + 1;
      while (e < rows.length && !rows[e].isHeader) {
        e++;
      }
      boundaries.add(e);
      i = e;
    } else {
      i++;
    }
  }

  target = target.clamp(0, rows.length);
  var best = boundaries.first;
  for (final b in boundaries) {
    if ((b - target).abs() < (best - target).abs()) best = b;
  }
  return best;
}
