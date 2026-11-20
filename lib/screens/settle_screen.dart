import 'package:material_ui/material_ui.dart';

import '../models/group.dart';
import '../models/member.dart';
import '../models/settlement.dart';
import '../services/database_helper.dart';
import '../utils/money.dart';

/// Record a settle-up payment between two members.
/// Defaults to the suggested payment for the biggest outstanding balance.
class SettleScreen extends StatefulWidget {
  final Group group;
  final List<Member> members;
  final Map<int, int> balances;

  const SettleScreen({
    super.key,
    required this.group,
    required this.members,
    required this.balances,
  });

  @override
  State<SettleScreen> createState() => _SettleScreenState();
}

class _SettleScreenState extends State<SettleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  int? _fromId;
  int? _toId;
  bool _saving = false;

  List<Member> get _debtors => widget.members
      .where((m) => (widget.balances[m.id] ?? 0) < 0)
      .toList();

  List<Member> get _creditors => widget.members
      .where((m) => (widget.balances[m.id] ?? 0) > 0)
      .toList();

  @override
  void initState() {
    super.initState();
    if (_debtors.isNotEmpty) _fromId = _debtors.first.id;
    if (_creditors.isNotEmpty) _toId = _creditors.first.id;
    _prefillAmount();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _prefillAmount() {
    if (_fromId == null || _toId == null) return;
    final owed = -(widget.balances[_fromId] ?? 0);
    final gets = widget.balances[_toId] ?? 0;
    final suggested = owed < gets ? owed : gets;
    if (suggested > 0) {
      _amountController.text = formatPaisePlain(suggested);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = parseRupeesToPaise(_amountController.text);
    if (amount == null || _fromId == null || _toId == null) return;
    if (_fromId == _toId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick two different members')),
      );
      return;
    }
    setState(() => _saving = true);
    await DatabaseHelper.instance.insertSettlement(
      Settlement(
        groupId: widget.group.id!,
        fromMemberId: _fromId!,
        toMemberId: _toId!,
        amountPaise: amount,
        createdAtMillis: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record settle-up')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_debtors.isEmpty || _creditors.isEmpty)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.check_circle, color: Colors.green),
                  title: Text('Everyone is settled up'),
                  subtitle: Text(
                    'There are no outstanding balances in this group.',
                  ),
                ),
              )
            else ...[
              DropdownButtonFormField<int>(
                initialValue: _fromId,
                decoration: const InputDecoration(
                  labelText: 'Paid by (owes money)',
                  border: OutlineInputBorder(),
                ),
                items: _debtors
                    .map(
                      (m) => DropdownMenuItem(
                        value: m.id,
                        child: Text(
                          '${m.name} (owes ${formatPaise(-(widget.balances[m.id] ?? 0))})',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() {
                  _fromId = value;
                  _prefillAmount();
                }),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _toId,
                decoration: const InputDecoration(
                  labelText: 'Paid to (is owed money)',
                  border: OutlineInputBorder(),
                ),
                items: _creditors
                    .map(
                      (m) => DropdownMenuItem(
                        value: m.id,
                        child: Text(
                          '${m.name} (gets ${formatPaise(widget.balances[m.id] ?? 0)})',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() {
                  _toId = value;
                  _prefillAmount();
                }),
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
                validator: (value) =>
                    parseRupeesToPaise(value ?? '') == null
                        ? 'Enter a valid amount'
                        : null,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Record payment'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
