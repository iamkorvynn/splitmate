/// A settle-up payment: [fromMemberId] paid [amountPaise] to [toMemberId].
class Settlement {
  final int? id;
  final int groupId;
  final int fromMemberId;
  final int toMemberId;
  final int amountPaise;
  final int createdAtMillis;

  const Settlement({
    this.id,
    required this.groupId,
    required this.fromMemberId,
    required this.toMemberId,
    required this.amountPaise,
    required this.createdAtMillis,
  });

  factory Settlement.fromMap(Map<String, Object?> map) {
    return Settlement(
      id: map['id'] as int?,
      groupId: map['group_id'] as int,
      fromMemberId: map['from_member_id'] as int,
      toMemberId: map['to_member_id'] as int,
      amountPaise: map['amount_paise'] as int,
      createdAtMillis: map['created_at'] as int,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'group_id': groupId,
      'from_member_id': fromMemberId,
      'to_member_id': toMemberId,
      'amount_paise': amountPaise,
      'created_at': createdAtMillis,
    };
  }
}

/// One suggested payment that settles balances with the fewest transfers.
class SuggestedPayment {
  final int fromMemberId;
  final int toMemberId;
  final int amountPaise;

  const SuggestedPayment({
    required this.fromMemberId,
    required this.toMemberId,
    required this.amountPaise,
  });
}
