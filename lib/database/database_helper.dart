import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/post.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('posts.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, fileName);
      return await openDatabase(
        path,
        version: 2,
        onCreate: _createDB,
        onUpgrade: _upgradeDB,
      );
    } catch (e) {
      throw Exception('Failed to initialize database: $e');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE posts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at TEXT NOT NULL,
        image_url TEXT NOT NULL DEFAULT ''
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE posts ADD COLUMN image_url TEXT NOT NULL DEFAULT ''");
    }
  }

  Future<int> insertPost(Post post) async {
    try {
      final db = await database;
      return await db.insert('posts', post.toMap());
    } catch (e) {
      throw Exception('Failed to insert post: $e');
    }
  }

  Future<List<Post>> getAllPosts() async {
    try {
      final db = await database;
      final maps = await db.query('posts', orderBy: 'created_at DESC');
      return maps.map((map) => Post.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to fetch posts: $e');
    }
  }

  Future<Post?> getPost(int id) async {
    try {
      final db = await database;
      final maps = await db.query('posts', where: 'id = ?', whereArgs: [id]);
      if (maps.isEmpty) return null;
      return Post.fromMap(maps.first);
    } catch (e) {
      throw Exception('Failed to fetch post: $e');
    }
  }

  Future<int> updatePost(Post post) async {
    try {
      if (post.id == null) throw Exception('Post ID is null');
      final db = await database;
      return await db.update('posts', post.toMap(), where: 'id = ?', whereArgs: [post.id]);
    } catch (e) {
      throw Exception('Failed to update post: $e');
    }
  }

  Future<int> deletePost(int id) async {
    try {
      final db = await database;
      return await db.delete('posts', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      throw Exception('Failed to delete post: $e');
    }
  }
}
