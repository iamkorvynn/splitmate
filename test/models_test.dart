import 'package:flutter_test/flutter_test.dart';
import 'package:splitmate/models/expense.dart';
import 'package:splitmate/models/group.dart';
import 'package:splitmate/models/member.dart';

void main() {
  group('Group', () {
    test('toMap/fromMap round-trips', () {
      const group = Group(
        id: 1,
        name: 'Goa Trip',
        note: 'Dec trip',
        createdAtMillis: 1700000000000,
      );
      final restored = Group.fromMap(group.toMap());
      expect(restored.id, 1);
      expect(restored.name, 'Goa Trip');
      expect(restored.note, 'Dec trip');
      expect(restored.createdAtMillis, 1700000000000);
    });

    test('note can be null', () {
      const group = Group(name: 'Flat', createdAtMillis: 1000);
      expect(Group.fromMap(group.toMap()).note, isNull);
    });

    test('copyWith keeps unchanged fields', () {
      const group = Group(id: 2, name: 'A', createdAtMillis: 5);
      final copy = group.copyWith(name: 'B');
      expect(copy.id, 2);
      expect(copy.name, 'B');
      expect(copy.createdAtMillis, 5);
    });
  });

  group('Member', () {
    test('toMap/fromMap round-trips', () {
      const member = Member(
        id: 7,
        groupId: 1,
        name: 'Asha',
        createdAtMillis: 1700000000000,
      );
      final restored = Member.fromMap(member.toMap());
      expect(restored.id, 7);
      expect(restored.groupId, 1);
      expect(restored.name, 'Asha');
      expect(restored.createdAtMillis, 1700000000000);
    });

    test('copyWith renames only the name', () {
      const member = Member(groupId: 1, name: 'Asha', createdAtMillis: 5);
      final copy = member.copyWith(name: 'Asha R');
      expect(copy.name, 'Asha R');
      expect(copy.groupId, 1);
    });
  });
}
