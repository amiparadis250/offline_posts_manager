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
        version: 4,
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
        image TEXT
      )
    ''');
    await _seedBlogs(db);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 4) {
      await db.execute('DROP TABLE IF EXISTS posts');
      await _createDB(db, newVersion);
    }
  }

  Future<void> _seedBlogs(Database db) async {
    final blogs = [
      {
        'title': 'Getting Started with Flutter',
        'content': 'Flutter is Google\'s UI toolkit for building natively compiled applications for mobile, web, and desktop from a single codebase. It uses the Dart programming language and provides a rich set of pre-designed widgets that make it easy to create beautiful, responsive apps.\n\nOne of Flutter\'s biggest advantages is hot reload, which lets you see changes instantly without losing app state. This makes development incredibly fast and enjoyable.',
        'created_at': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
      },
      {
        'title': 'Understanding SQLite in Mobile Apps',
        'content': 'SQLite is a lightweight, serverless database engine that runs directly on the device. Unlike cloud databases, SQLite requires no internet connection, making it perfect for offline-first applications.\n\nIn Flutter, the sqflite package provides full access to SQLite. You can create tables, run queries, and manage data just like any SQL database — all stored locally on the user\'s device.',
        'created_at': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
      },
      {
        'title': 'Why Offline-First Matters',
        'content': 'In many parts of the world, internet connectivity is unreliable. Offline-first apps ensure users can always access and modify their data, regardless of network conditions.\n\nBy storing data locally with SQLite and syncing when connectivity returns, apps provide a seamless experience. This approach improves reliability, speed, and user satisfaction.',
        'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      },
      {
        'title': 'Best Practices for State Management',
        'content': 'State management is one of the most important concepts in Flutter development. Whether you use setState, Provider, Riverpod, or Bloc, the key is choosing the right tool for your app\'s complexity.\n\nFor simple apps, setState works perfectly. As your app grows, consider Provider or Riverpod for better separation of concerns and testability.',
        'created_at': DateTime.now().toIso8601String(),
      },
    ];
    for (final blog in blogs) {
      await db.insert('posts', blog);
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
