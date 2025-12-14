import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/album.dart';
import '../models/photo.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('work_camera.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';

    await db.execute('''
      CREATE TABLE users (
        id $idType,
        username $textType UNIQUE,
        password $textType,
        name $textType,
        created_at $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE albums (
        id $idType,
        name $textType,
        user_id $integerType,
        created_at $textType,
        is_auto_generated $integerType,
        auto_delete_days INTEGER DEFAULT 0,
        delete_album_with_photos INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE photos (
        id $idType,
        path $textType,
        album_id $integerType,
        user_id $integerType,
        taken_at $textType,
        taken_by $textType,
        is_video INTEGER DEFAULT 0,
        is_favorite INTEGER DEFAULT 0,
        FOREIGN KEY (album_id) REFERENCES albums (id),
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE albums ADD COLUMN auto_delete_days INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE albums ADD COLUMN delete_album_with_photos INTEGER DEFAULT 0');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE photos ADD COLUMN is_video INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE photos ADD COLUMN is_favorite INTEGER DEFAULT 0');
    }
  }
  
  Future<int> updatePhotoFavorite(int id, bool isFavorite) async {
    final db = await database;
    return await db.update(
      'photos',
      {'is_favorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<User?> createUser(User user) async {
    final db = await database;
    try {
      final id = await db.insert('users', user.toMap());
      return user.copyWith(id: id);
    } catch (e) {
      print('Kullanıcı oluşturma hatası: $e');
      return null;
    }
  }

  Future<User?> getUserByUsername(String username) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<User?> login(String username, String password) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<Album> createAlbum(Album album) async {
    final db = await database;
    final id = await db.insert('albums', album.toMap());
    return album.copyWith(id: id);
  }

  Future<List<Album>> getAlbumsByUserId(int userId) async {
    final db = await database;
    final maps = await db.query(
      'albums',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => Album.fromMap(map)).toList();
  }

  Future<Album?> getAlbumByNameAndDate(int userId, String name) async {
    final db = await database;
    final maps = await db.query(
      'albums',
      where: 'user_id = ? AND name = ?',
      whereArgs: [userId, name],
    );

    if (maps.isNotEmpty) {
      return Album.fromMap(maps.first);
    }
    return null;
  }

  Future<int> deleteAlbum(int id) async {
    final db = await database;
    await db.delete('photos', where: 'album_id = ?', whereArgs: [id]);
    return await db.delete('albums', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateAlbum(Album album) async {
    final db = await database;
    return await db.update(
      'albums',
      album.toMap(),
      where: 'id = ?',
      whereArgs: [album.id],
    );
  }

  Future<Album?> getAlbumById(int id) async {
    final db = await database;
    final maps = await db.query(
      'albums',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Album.fromMap(maps.first);
    }
    return null;
  }

  Future<Photo> createPhoto(Photo photo) async {
    final db = await database;
    final id = await db.insert('photos', photo.toMap());
    return photo.copyWith(id: id);
  }

  Future<List<Photo>> getPhotosByAlbumId(int albumId) async {
    final db = await database;
    final maps = await db.query(
      'photos',
      where: 'album_id = ?',
      whereArgs: [albumId],
      orderBy: 'taken_at DESC',
    );

    return maps.map((map) => Photo.fromMap(map)).toList();
  }

  Future<List<Photo>> getPhotosByUserId(int userId) async {
    final db = await database;
    final maps = await db.query(
      'photos',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'taken_at DESC',
    );

    return maps.map((map) => Photo.fromMap(map)).toList();
  }

  Future<int> deletePhoto(int id) async {
    final db = await database;
    return await db.delete('photos', where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await database;
    db.close();
  }
}

extension UserExtension on User {
  User copyWith({
    int? id,
    String? username,
    String? password,
    String? name,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}


extension PhotoExtension on Photo {
  Photo copyWith({
    int? id,
    String? path,
    int? albumId,
    int? userId,
    DateTime? takenAt,
    String? takenBy,
    bool? isVideo,
    bool? isFavorite,
  }) {
    return Photo(
      id: id ?? this.id,
      path: path ?? this.path,
      albumId: albumId ?? this.albumId,
      userId: userId ?? this.userId,
      takenAt: takenAt ?? this.takenAt,
      takenBy: takenBy ?? this.takenBy,
      isVideo: isVideo ?? this.isVideo,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
