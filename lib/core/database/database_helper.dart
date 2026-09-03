import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

import '../models/user_model.dart';
import '../models/pokemon_collection_model.dart';
import '../models/trade_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'pokemon_collector.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        avatar_url TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE pokemon_collection (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        pokemon_id INTEGER NOT NULL,
        pokemon_name TEXT NOT NULL,
        sprite_url TEXT NOT NULL,
        types TEXT NOT NULL,
        obtained_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE trades (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        from_user_id INTEGER NOT NULL,
        from_username TEXT NOT NULL,
        to_user_id INTEGER NOT NULL,
        to_username TEXT NOT NULL,
        offered_pokemon_collection_id INTEGER NOT NULL,
        offered_pokemon_name TEXT NOT NULL,
        offered_pokemon_sprite TEXT NOT NULL,
        requested_pokemon_collection_id INTEGER NOT NULL,
        requested_pokemon_name TEXT NOT NULL,
        requested_pokemon_sprite TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        created_at TEXT NOT NULL,
        FOREIGN KEY (from_user_id) REFERENCES users(id),
        FOREIGN KEY (to_user_id) REFERENCES users(id)
      )
    ''');
  }

  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  Future<UserModel?> registerUser(String username, String password) async {
    final db = await database;
    final existing = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    if (existing.isNotEmpty) return null;

    final user = UserModel(
      username: username,
      passwordHash: hashPassword(password),
      avatarUrl:
          'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/${_randomAvatarId()}.png',
      createdAt: DateTime.now(),
    );

    final id = await db.insert('users', user.toMap());
    return user.copyWith(id: id);
  }

  Future<UserModel?> loginUser(String username, String password) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'username = ? AND password_hash = ?',
      whereArgs: [username, hashPassword(password)],
    );
    if (result.isEmpty) return null;
    return UserModel.fromMap(result.first);
  }

  Future<List<UserModel>> getAllUsers({int? excludeUserId}) async {
    final db = await database;
    final result = excludeUserId != null
        ? await db.query('users', where: 'id != ?', whereArgs: [excludeUserId])
        : await db.query('users');
    return result.map(UserModel.fromMap).toList();
  }

  int _randomAvatarId() => DateTime.now().millisecondsSinceEpoch % 898 + 1;

  Future<PokemonCollectionModel> addPokemonToCollection(
      PokemonCollectionModel entry) async {
    final db = await database;
    final id = await db.insert('pokemon_collection', entry.toMap());
    return PokemonCollectionModel(
      id: id,
      userId: entry.userId,
      pokemonId: entry.pokemonId,
      pokemonName: entry.pokemonName,
      spriteUrl: entry.spriteUrl,
      types: entry.types,
      obtainedAt: entry.obtainedAt,
    );
  }

  Future<List<PokemonCollectionModel>> getUserCollection(int userId) async {
    final db = await database;
    final result = await db.query(
      'pokemon_collection',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'obtained_at DESC',
    );
    return result.map(PokemonCollectionModel.fromMap).toList();
  }

  Future<List<PokemonCollectionModel>> getUserCollectionExcludingPending(
      int userId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT pc.* FROM pokemon_collection pc
      WHERE pc.user_id = ?
        AND pc.id NOT IN (
          SELECT offered_pokemon_collection_id FROM trades
          WHERE from_user_id = ? AND status = 'pending'
        )
    ''', [userId, userId]);
    return result.map(PokemonCollectionModel.fromMap).toList();
  }

  Future<void> removePokemonFromCollection(int collectionId) async {
    final db = await database;
    await db.delete(
      'pokemon_collection',
      where: 'id = ?',
      whereArgs: [collectionId],
    );
  }

  Future<void> transferPokemon(int collectionId, int newUserId) async {
    final db = await database;
    await db.update(
      'pokemon_collection',
      {'user_id': newUserId},
      where: 'id = ?',
      whereArgs: [collectionId],
    );
  }

  Future<TradeModel> createTrade(TradeModel trade) async {
    final db = await database;
    final id = await db.insert('trades', trade.toMap());
    return TradeModel(
      id: id,
      fromUserId: trade.fromUserId,
      fromUsername: trade.fromUsername,
      toUserId: trade.toUserId,
      toUsername: trade.toUsername,
      offeredPokemonCollectionId: trade.offeredPokemonCollectionId,
      offeredPokemonName: trade.offeredPokemonName,
      offeredPokemonSprite: trade.offeredPokemonSprite,
      requestedPokemonCollectionId: trade.requestedPokemonCollectionId,
      requestedPokemonName: trade.requestedPokemonName,
      requestedPokemonSprite: trade.requestedPokemonSprite,
      status: trade.status,
      createdAt: trade.createdAt,
    );
  }

  Future<List<TradeModel>> getTradesForUser(int userId) async {
    final db = await database;
    final result = await db.query(
      'trades',
      where: 'from_user_id = ? OR to_user_id = ?',
      whereArgs: [userId, userId],
      orderBy: 'created_at DESC',
    );
    return result.map(TradeModel.fromMap).toList();
  }

  Future<void> updateTradeStatus(int tradeId, TradeStatus status) async {
    final db = await database;
    await db.update(
      'trades',
      {'status': status.name},
      where: 'id = ?',
      whereArgs: [tradeId],
    );
  }

  Future<void> acceptTrade(TradeModel trade) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        'pokemon_collection',
        {'user_id': trade.toUserId},
        where: 'id = ?',
        whereArgs: [trade.offeredPokemonCollectionId],
      );
      await txn.update(
        'pokemon_collection',
        {'user_id': trade.fromUserId},
        where: 'id = ?',
        whereArgs: [trade.requestedPokemonCollectionId],
      );
      await txn.update(
        'trades',
        {'status': TradeStatus.accepted.name},
        where: 'id = ?',
        whereArgs: [trade.id],
      );
    });
  }
}
