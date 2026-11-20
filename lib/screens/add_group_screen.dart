import 'package:material_ui/material_ui.dart';

import '../models/group.dart';
import '../models/member.dart';
import '../services/database_helper.dart';

/// Create a group and its first members.
class AddGroupScreen extends StatefulWidget {
  const AddGroupScreen({super.key});

  @override
  State<AddGroupScreen> createState() => _AddGroupScreenState();
}

class _AddGroupScreenState extends State<AddGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _noteController = TextEditingController();
  final _memberController = TextEditingController();
  final List<String> _members = [];
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    _memberController.dispose();
    super.dispose();
  }

  void _addMember() {
    final name = _memberController.text.trim();
    if (name.isEmpty) return;
    if (_members.any((m) => m.toLowerCase() == name.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('“$name” is already in the group')),
      );
      return;
    }
    setState(() {
      _members.add(name);
      _memberController.clear();
    });
  }

  void _removeMember(String name) {
    setState(() => _members.remove(name));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one member')),
      );
      return;
    }
    setState(() => _saving = true);
    final now = DateTime.now().millisecondsSinceEpoch;
    final groupId = await DatabaseHelper.instance.insertGroup(
      Group(
        name: _nameController.text.trim(),
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        createdAtMillis: now,
      ),
    );
    for (final name in _members) {
      await DatabaseHelper.instance.insertMember(
        Member(groupId: groupId, name: name, createdAtMillis: now),
      );
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New group')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Group name',
                hintText: 'e.g. Goa Trip, Flat 302, College Friends',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Enter a name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            Text(
              'Members',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _memberController,
                    decoration: const InputDecoration(
                      labelText: 'Member name',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                    onSubmitted: (_) => _addMember(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _addMember,
                  icon: const Icon(Icons.add),
                  tooltip: 'Add member',
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._members.map(
              (name) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(name[0].toUpperCase()),
                  ),
                  title: Text(name),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => _removeMember(name),
                  ),
                ),
              ),
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
                  : const Text('Create group'),
            ),
          ],
        ),
      ),
    );
  }
}
