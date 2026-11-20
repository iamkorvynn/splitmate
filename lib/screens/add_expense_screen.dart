import 'package:material_ui/material_ui.dart';

import '../models/expense.dart';
import '../models/group.dart';
import '../models/member.dart';
import '../services/database_helper.dart';
import '../utils/money.dart';

/// Add an expense to a group: title, amount, who paid, and how it splits
/// (equally across chosen members, or custom shares per member).
class AddExpenseScreen extends StatefulWidget {
  final Group group;
  final List<Member> members;

  const AddExpenseScreen({
    super.key,
    required this.group,
    required this.members,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  int? _paidById;
  late Set<int> _splitAmong;
  bool _customSplit = false;
  final Map<int, TextEditingController> _shareControllers = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _paidById = widget.members.isNotEmpty ? widget.members.first.id : null;
    _splitAmong = widget.members.map((m) => m.id!).toSet();
    for (final member in widget.members) {
      _shareControllers[member.id!] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    for (final c in _shareControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  int? get _amountPaise => parseRupeesToPaise(_amountController.text);

  String? _validateCustomShares() {
    final amount = _amountPaise;
    if (amount == null) return 'Enter a valid amount first';
    var total = 0;
    for (final id in _splitAmong) {
      final share = parseRupeesToPaise(_shareControllers[id]!.text);
      if (share == null) return 'Enter a share for every selected member';
      total += share;
    }
    if (total != amount) {
      return 'Shares add up to ${formatPaise(total)} but the expense is '
          '${formatPaise(amount)}';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = _amountPaise;
    if (amount == null || _paidById == null || _splitAmong.isEmpty) return;
    if (_customSplit) {
      final error = _validateCustomShares();
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
        return;
      }
    }
    setState(() => _saving = true);

    final Map<int, int> shares;
    if (_customSplit) {
      shares = {
        for (final id in _splitAmong)
          id: parseRupeesToPaise(_shareControllers[id]!.text)!,
      };
    } else {
      final ids = _splitAmong.toList();
      final amounts = splitEqually(amount, ids.length);
      shares = {for (var i = 0; i < ids.length; i++) ids[i]: amounts[i]};
    }

    await DatabaseHelper.instance.insertExpense(
      Expense(
        groupId: widget.group.id!,
        title: _titleController.text.trim(),
        amountPaise: amount,
        paidByMemberId: _paidById!,
        createdAtMillis: DateTime.now().millisecondsSinceEpoch,
        shares: shares,
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final amount = _amountPaise;
    return Scaffold(
      appBar: AppBar(title: const Text('Add expense')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'What was it for?',
                hintText: 'e.g. Dinner, Taxi, Hotel',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Enter a title' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount (₹)',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              validator: (value) => parseRupeesToPaise(value ?? '') == null
                  ? 'Enter a valid amount'
                  : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _paidById,
              decoration: const InputDecoration(
                labelText: 'Paid by',
                border: OutlineInputBorder(),
              ),
              items: widget.members
                  .map(
                    (m) => DropdownMenuItem(value: m.id, child: Text(m.name)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _paidById = value),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Text(
                  'Split between',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                const Text('Custom shares'),
                Switch(
                  value: _customSplit,
                  onChanged: (value) => setState(() => _customSplit = value),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...widget.members.map((member) {
              final selected = _splitAmong.contains(member.id);
              final index = _splitAmong.toList().indexOf(member.id!);
              final equalShare = amount != null && selected
                  ? splitEqually(amount, _splitAmong.length)[index]
                  : 0;
              return CheckboxListTile(
                value: selected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _splitAmong.add(member.id!);
                    } else {
                      _splitAmong.remove(member.id);
                    }
                  });
                },
                title: Text(member.name),
                subtitle: selected && !_customSplit && amount != null
                    ? Text('owes ${formatPaise(equalShare)}')
                    : null,
                secondary: _customSplit && selected
                    ? SizedBox(
                        width: 110,
                        child: TextField(
                          controller: _shareControllers[member.id],
                          decoration: const InputDecoration(
                            prefixText: '₹ ',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      )
                    : null,
              );
            }),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save expense'),
            ),
          ],
        ),
      ),
    );
  }
}
