import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/expense.dart';
import '../models/group.dart';
import '../models/member.dart';
import '../models/settlement.dart';

/// Local SQLite storage for SplitMate. Everything lives on-device;
/// there are no network calls and no seed or sample data.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'splitmate.db';
  static const _dbVersion = 1;

  Database? _db;

  /// Single-flight future so concurrent first calls share one open.
  /// Without this, two callers racing the first open would each create
  /// their own connection — and for an in-memory database those are two
  /// different, empty databases.
  Future<Database>? _dbFuture;

  /// Test seam: lets tests point the helper at an in-memory database.
  String Function()? testPathOverride;

  Future<Database> get database {
    final existing = _db;
    if (existing != null) return Future.value(existing);
    return _dbFuture ??= _open().then((db) {
      _db = db;
      return db;
    });
  }

  Future<Database> _open() async {
    final path = testPathOverride != null
        ? testPathOverride!()
        : p.join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE groups(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            note TEXT,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE members(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            group_id INTEGER NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
            name TEXT NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE expenses(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            group_id INTEGER NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
            title TEXT NOT NULL,
            amount_paise INTEGER NOT NULL,
            paid_by_member_id INTEGER NOT NULL REFERENCES members(id),
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE expense_shares(
            expense_id INTEGER NOT NULL REFERENCES expenses(id) ON DELETE CASCADE,
            member_id INTEGER NOT NULL REFERENCES members(id),
            share_paise INTEGER NOT NULL,
            PRIMARY KEY (expense_id, member_id)
          )
        ''');
        await db.execute('''
          CREATE TABLE settlements(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            group_id INTEGER NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
            from_member_id INTEGER NOT NULL REFERENCES members(id),
            to_member_id INTEGER NOT NULL REFERENCES members(id),
            amount_paise INTEGER NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  Future<void> close() async {
    _dbFuture = null;
    await _db?.close();
    _db = null;
  }

  // ---------------------------------------------------------------- groups

  Future<int> insertGroup(Group group) async {
    final db = await database;
    return db.insert('groups', group.toMap()..remove('id'));
  }

  Future<List<Group>> getGroups() async {
    final db = await database;
    final rows = await db.query('groups', orderBy: 'created_at DESC');
    return rows.map(Group.fromMap).toList();
  }

  Future<Group?> getGroup(int id) async {
    final db = await database;
    final rows = await db.query('groups', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Group.fromMap(rows.first);
  }

  Future<void> updateGroup(Group group) async {
    final db = await database;
    await db.update(
      'groups',
      group.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [group.id],
    );
  }

  Future<void> deleteGroup(int id) async {
    final db = await database;
    await db.delete('groups', where: 'id = ?', whereArgs: [id]);
  }

  // --------------------------------------------------------------- members

  Future<int> insertMember(Member member) async {
    final db = await database;
    return db.insert('members', member.toMap()..remove('id'));
  }

  Future<List<Member>> getMembers(int groupId) async {
    final db = await database;
    final rows = await db.query(
      'members',
      where: 'group_id = ?',
      whereArgs: [groupId],
      orderBy: 'created_at ASC',
    );
    return rows.map(Member.fromMap).toList();
  }

  Future<void> updateMember(Member member) async {
    final db = await database;
    await db.update(
      'members',
      member.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [member.id],
    );
  }

  Future<void> deleteMember(int id) async {
    final db = await database;
    await db.delete('members', where: 'id = ?', whereArgs: [id]);
  }

  // -------------------------------------------------------------- expenses

  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    return db.transaction((txn) async {
      final expenseId = await txn.insert(
        'expenses',
        expense.toMap()..remove('id'),
      );
      for (final entry in expense.shares.entries) {
        await txn.insert('expense_shares', {
          'expense_id': expenseId,
          'member_id': entry.key,
          'share_paise': entry.value,
        });
      }
      return expenseId;
    });
  }

  Future<List<Expense>> getExpenses(int groupId) async {
    final db = await database;
    final rows = await db.query(
      'expenses',
      where: 'group_id = ?',
      whereArgs: [groupId],
      orderBy: 'created_at DESC',
    );
    final expenses = <Expense>[];
    for (final row in rows) {
      final expense = Expense.fromMap(row);
      final shareRows = await db.query(
        'expense_shares',
        where: 'expense_id = ?',
        whereArgs: [expense.id],
      );
      final shares = <int, int>{
        for (final s in shareRows)
          s['member_id'] as int: s['share_paise'] as int,
      };
      expenses.add(expense.copyWith(shares: shares));
    }
    return expenses;
  }

  Future<void> deleteExpense(int id) async {
    final db = await database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  // ------------------------------------------------------------ settlements

  Future<int> insertSettlement(Settlement settlement) async {
    final db = await database;
    return db.insert('settlements', settlement.toMap()..remove('id'));
  }

  Future<List<Settlement>> getSettlements(int groupId) async {
    final db = await database;
    final rows = await db.query(
      'settlements',
      where: 'group_id = ?',
      whereArgs: [groupId],
      orderBy: 'created_at DESC',
    );
    return rows.map(Settlement.fromMap).toList();
  }

  Future<void> deleteSettlement(int id) async {
    final db = await database;
    await db.delete('settlements', where: 'id = ?', whereArgs: [id]);
  }
}
