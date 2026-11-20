/// One expense inside a group.
///
/// Amounts are stored in paise (see [money.dart]).
/// [shares] maps a member id to the paise that member owes for this expense.
/// The shares always add up to [amountPaise].
class Expense {
  final int? id;
  final int groupId;
  final String title;
  final int amountPaise;
  final int paidByMemberId;
  final int createdAtMillis;
  final Map<int, int> shares;

  const Expense({
    this.id,
    required this.groupId,
    required this.title,
    required this.amountPaise,
    required this.paidByMemberId,
    required this.createdAtMillis,
    this.shares = const {},
  });

  factory Expense.fromMap(Map<String, Object?> map) {
    return Expense(
      id: map['id'] as int?,
      groupId: map['group_id'] as int,
      title: map['title'] as String,
      amountPaise: map['amount_paise'] as int,
      paidByMemberId: map['paid_by_member_id'] as int,
      createdAtMillis: map['created_at'] as int,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'group_id': groupId,
      'title': title,
      'amount_paise': amountPaise,
      'paid_by_member_id': paidByMemberId,
      'created_at': createdAtMillis,
    };
  }

  Expense copyWith({
    int? id,
    int? groupId,
    String? title,
    int? amountPaise,
    int? paidByMemberId,
    int? createdAtMillis,
    Map<int, int>? shares,
  }) {
    return Expense(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      title: title ?? this.title,
      amountPaise: amountPaise ?? this.amountPaise,
      paidByMemberId: paidByMemberId ?? this.paidByMemberId,
      createdAtMillis: createdAtMillis ?? this.createdAtMillis,
      shares: shares ?? this.shares,
    );
  }
}
