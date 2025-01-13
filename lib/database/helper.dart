import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/ticket.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'tickets.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tickets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT,
        title TEXT,
        dateAdded TEXT
      )
    ''');
  }

  Future<void> insertTicket(Ticket ticket) async {
    final db = await database;
    await db.insert('tickets', ticket.toMap());
  }

  Future<List<Ticket>> getTickets() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('tickets');
    return List.generate(maps.length, (i) => Ticket.fromMap(maps[i]));
  }

  Future<bool> ticketExists(String code) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'tickets',
      where: 'code = ?',
      whereArgs: [code],
    );
    return result.isNotEmpty;
  }

  Future<void> deleteTicket(int id) async {
    final db = await database;
    await db.delete(
      'tickets',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateTicketTitle(int id, String newTitle) async {
    final db = await database;
    await db.update(
      'tickets',
      {'title': newTitle},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}