/// A group of people who split expenses together.
class Group {
  final int? id;
  final String name;
  final String? note;
  final int createdAtMillis;

  const Group({
    this.id,
    required this.name,
    this.note,
    required this.createdAtMillis,
  });

  factory Group.fromMap(Map<String, Object?> map) {
    return Group(
      id: map['id'] as int?,
      name: map['name'] as String,
      note: map['note'] as String?,
      createdAtMillis: map['created_at'] as int,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'note': note,
      'created_at': createdAtMillis,
    };
  }

  Group copyWith({int? id, String? name, String? note, int? createdAtMillis}) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      note: note ?? this.note,
      createdAtMillis: createdAtMillis ?? this.createdAtMillis,
    );
  }
}
