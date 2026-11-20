/// A person inside a group.
class Member {
  final int? id;
  final int groupId;
  final String name;
  final int createdAtMillis;

  const Member({
    this.id,
    required this.groupId,
    required this.name,
    required this.createdAtMillis,
  });

  factory Member.fromMap(Map<String, Object?> map) {
    return Member(
      id: map['id'] as int?,
      groupId: map['group_id'] as int,
      name: map['name'] as String,
      createdAtMillis: map['created_at'] as int,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'group_id': groupId,
      'name': name,
      'created_at': createdAtMillis,
    };
  }

  Member copyWith({int? id, int? groupId, String? name, int? createdAtMillis}) {
    return Member(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      createdAtMillis: createdAtMillis ?? this.createdAtMillis,
    );
  }
}
