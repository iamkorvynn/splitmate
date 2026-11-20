import 'package:material_ui/material_ui.dart';

import '../models/expense.dart';
import '../models/group.dart';
import '../models/member.dart';
import '../models/settlement.dart';
import '../services/balance_calculator.dart';
import '../services/database_helper.dart';
import '../utils/money.dart';
import '../widgets/balance_chip.dart';
import '../widgets/expense_detail_sheet.dart';
import '../widgets/expense_tile.dart';
import '../widgets/member_avatar.dart';
import 'add_expense_screen.dart';
import 'settle_screen.dart';

/// Group detail with three tabs: Expenses, Balances, Settlements.
/// Also manages group members (add / remove).
class GroupDetailScreen extends StatefulWidget {
  final Group group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  late Group _group;
  List<Member> _members = [];
  List<Expense> _expenses = [];
  List<Settlement> _settlements = [];
  bool _loading = true;

  Map<int, String> get _memberNames => {
        for (final m in _members) m.id!: m.name,
      };

  @override
  void initState() {
    super.initState();
    _group = widget.group;
    _loadAll();
  }

  Future<void> _loadAll() async {
    final db = DatabaseHelper.instance;
    final members = await db.getMembers(_group.id!);
    final expenses = await db.getExpenses(_group.id!);
    final settlements = await db.getSettlements(_group.id!);
    if (!mounted) return;
    setState(() {
      _members = members;
      _expenses = expenses;
      _settlements = settlements;
      _loading = false;
    });
  }

  Map<int, int> get _balances => BalanceCalculator.computeBalances(
        memberIds: _members.map((m) => m.id!).toList(),
        expenses: _expenses,
        settlements: _settlements,
      );

  Future<void> _showEditGroup() async {
    final nameController = TextEditingController(text: _group.name);
    final noteController = TextEditingController(text: _group.note ?? '');
    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit group'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Group name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a name'
                    : null,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved == true) {
      final updated = _group.copyWith(
        name: nameController.text.trim(),
        note: noteController.text.trim().isEmpty
            ? null
            : noteController.text.trim(),
      );
      await DatabaseHelper.instance.updateGroup(updated);
      if (!mounted) return;
      setState(() => _group = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group updated')),
      );
    }
  }

  Future<void> _openAddExpense() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(
          group: _group,
          members: _members,
        ),
      ),
    );
    if (added == true) _loadAll();
  }

  Future<void> _settleAll() async {
    final suggestions = BalanceCalculator.simplifyDebts(_balances);
    if (suggestions.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settle all balances?'),
        content: Text(
          '${suggestions.length} payment(s) will be recorded to settle '
          'everyone up in this group.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Settle all'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final payment in suggestions) {
      await DatabaseHelper.instance.insertSettlement(
        Settlement(
          groupId: _group.id!,
          fromMemberId: payment.fromMemberId,
          toMemberId: payment.toMemberId,
          amountPaise: payment.amountPaise,
          createdAtMillis: now,
        ),
      );
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All settled up!')),
    );
    _loadAll();
  }

  Future<void> _openSettle() async {
    final settled = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SettleScreen(
          group: _group,
          members: _members,
          balances: _balances,
        ),
      ),
    );
    if (settled == true) _loadAll();
  }

  Future<void> _showExpenseDetail(Expense expense) async {
    await ExpenseDetailSheet.show(
      context,
      expense: expense,
      payerName: _memberNames[expense.paidByMemberId] ?? 'Unknown',
      memberNames: _memberNames,
    );
  }

  Future<void> _deleteExpense(Expense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete expense?'),
        content: Text(
          '“${expense.title}” (${formatPaise(expense.amountPaise)}) '
          'will be removed and balances recalculated.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await DatabaseHelper.instance.deleteExpense(expense.id!);
      _loadAll();
    }
  }

  Future<void> _showAddMember() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add member'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Member name',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
          onSubmitted: (_) => Navigator.of(context).pop(controller.text.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    if (_members.any((m) => m.name.toLowerCase() == name.toLowerCase())) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('“$name” is already a member')),
      );
      return;
    }
    await DatabaseHelper.instance.insertMember(
      Member(
        groupId: _group.id!,
        name: name,
        createdAtMillis: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    _loadAll();
  }

  Future<void> _removeMember(Member member) async {
    final hasActivity = _expenses.any(
          (e) =>
              e.paidByMemberId == member.id ||
              e.shares.containsKey(member.id),
        ) ||
        _settlements.any(
          (s) => s.fromMemberId == member.id || s.toMemberId == member.id,
        );
    if (hasActivity) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot remove ${member.name}: they have expenses or settlements',
          ),
        ),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove member?'),
        content: Text('${member.name} will be removed from this group.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await DatabaseHelper.instance.deleteMember(member.id!);
      _loadAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalSpent = BalanceCalculator.totalSpent(_expenses);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_group.name),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit group',
              onPressed: _showEditGroup,
            ),
            IconButton(
              icon: const Icon(Icons.person_add),
              tooltip: 'Add member',
              onPressed: _showAddMember,
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Expenses'),
              Tab(text: 'Balances'),
              Tab(text: 'Settlements'),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _SummaryBar(
                    totalSpent: totalSpent,
                    memberCount: _members.length,
                    expenseCount: _expenses.length,
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _ExpensesTab(
                          expenses: _expenses,
                          memberNames: _memberNames,
                          onDelete: _deleteExpense,
                          onTap: _showExpenseDetail,
                          onAdd: _openAddExpense,
                        ),
                        _BalancesTab(
                          members: _members,
                          expenses: _expenses,
                          balances: _balances,
                          onRemoveMember: _removeMember,
                          onSettle: _openSettle,
                          onSettleAll: _settleAll,
                        ),
                        _SettlementsTab(
                          settlements: _settlements,
                          memberNames: _memberNames,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openAddExpense,
          icon: const Icon(Icons.add),
          label: const Text('Add expense'),
        ),
      ),
    );
  }
}

class _SummaryBar extends StatelessWidget {
  final int totalSpent;
  final int memberCount;
  final int expenseCount;

  const _SummaryBar({
    required this.totalSpent,
    required this.memberCount,
    required this.expenseCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total spent', style: TextStyle(fontSize: 12)),
                Text(
                  formatPaise(totalSpent),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Text('$memberCount members'),
          const SizedBox(width: 12),
          Text('$expenseCount expenses'),
        ],
      ),
    );
  }
}

class _ExpensesTab extends StatelessWidget {
  final List<Expense> expenses;
  final Map<int, String> memberNames;
  final void Function(Expense) onDelete;
  final void Function(Expense) onTap;
  final VoidCallback onAdd;

  const _ExpensesTab({
    required this.expenses,
    required this.memberNames,
    required this.onDelete,
    required this.onTap,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'No expenses yet',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Add the first expense and SplitMate will split it '
                'between the members.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Add expense'),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      itemCount: expenses.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final expense = expenses[index];
        return ExpenseTile(
          expense: expense,
          payerName: memberNames[expense.paidByMemberId] ?? 'Unknown',
          onDelete: () => onDelete(expense),
          onTap: () => onTap(expense),
        );
      },
    );
  }
}

class _BalancesTab extends StatelessWidget {
  final List<Member> members;
  final List<Expense> expenses;
  final Map<int, int> balances;
  final void Function(Member) onRemoveMember;
  final VoidCallback onSettle;

  const _BalancesTab({
    required this.members,
    required this.expenses,
    required this.balances,
    required this.onRemoveMember,
    required this.onSettle,
  });

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return const Center(child: Text('No members in this group yet.'));
    }
    final paidTotals = <int, int>{for (final m in members) m.id!: 0};
    final shareTotals = <int, int>{for (final m in members) m.id!: 0};
    for (final expense in expenses) {
      paidTotals[expense.paidByMemberId] =
          (paidTotals[expense.paidByMemberId] ?? 0) + expense.amountPaise;
      for (final entry in expense.shares.entries) {
        shareTotals[entry.key] =
            (shareTotals[entry.key] ?? 0) + entry.value;
      }
    }
    final suggestions = BalanceCalculator.simplifyDebts(balances);
    final allSettled = balances.values.every((b) => b == 0);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...members.map(
          (member) => Card(
            child: ListTile(
              leading: MemberAvatar(name: member.name),
              title: Text(member.name),
              subtitle: Text(
                'paid ${formatPaise(paidTotals[member.id] ?? 0)} • '
                'share ${formatPaise(shareTotals[member.id] ?? 0)}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BalanceChip(balancePaise: balances[member.id] ?? 0),
                  IconButton(
                    icon: const Icon(Icons.person_remove_outlined, size: 20),
                    tooltip: 'Remove member',
                    onPressed: () => onRemoveMember(member),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (allSettled)
          const Card(
            color: Colors.green,
            child: ListTile(
              leading: Icon(Icons.check_circle, color: Colors.white),
              title: Text(
                'All settled up!',
                style: TextStyle(color: Colors.white),
              ),
            ),
          )
        else ...[
          Text(
            'Suggested settle-ups',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...suggestions.map(
            (payment) => Card(
              child: ListTile(
                leading: const Icon(Icons.swap_horiz),
                title: Text(
                  '${members.firstWhere((m) => m.id == payment.fromMemberId).name} '
                  'pays '
                  '${members.firstWhere((m) => m.id == payment.toMemberId).name}',
                ),
                trailing: Text(
                  formatPaise(payment.amountPaise),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onSettle,
            icon: const Icon(Icons.handshake),
            label: const Text('Record a settle-up'),
          ),
        ],
      ],
    );
  }
}

class _SettlementsTab extends StatelessWidget {
  final List<Settlement> settlements;
  final Map<int, String> memberNames;

  const _SettlementsTab({
    required this.settlements,
    required this.memberNames,
  });

  @override
  Widget build(BuildContext context) {
    if (settlements.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No settlements recorded yet.\nUse “Settle up” from the Balances '
            'tab after adding expenses.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.separated(
      itemCount: settlements.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final settlement = settlements[index];
        final date = DateTime.fromMillisecondsSinceEpoch(
          settlement.createdAtMillis,
        );
        return ListTile(
          leading: const Icon(Icons.handshake_outlined),
          title: Text(
            '${memberNames[settlement.fromMemberId] ?? 'Unknown'} paid '
            '${memberNames[settlement.toMemberId] ?? 'Unknown'}',
          ),
          subtitle: Text(
            '${date.day}/${date.month}/${date.year}',
          ),
          trailing: Text(
            formatPaise(settlement.amountPaise),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }
}
