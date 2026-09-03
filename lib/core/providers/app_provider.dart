import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/pokemon_collection_model.dart';
import '../models/trade_model.dart';
import '../database/database_helper.dart';
import '../services/pokeapi_service.dart';

class AppProvider extends ChangeNotifier {
  final DatabaseHelper _db   = DatabaseHelper();
  final PokeApiService _poke = PokeApiService();

  UserModel? _currentUser;
  List<PokemonCollectionModel> _collection = [];
  List<TradeModel> _trades = [];
  bool _loading = false;
  String? _error;

  UserModel? get currentUser  => _currentUser;
  List<PokemonCollectionModel> get collection => _collection;
  List<TradeModel> get trades => _trades;
  bool get loading            => _loading;
  String? get error           => _error;
  bool get isLoggedIn         => _currentUser != null;

  void _setLoading(bool v)    { _loading = v; notifyListeners(); }
  void _setError(String? msg) { _error   = msg; notifyListeners(); }
  void clearError()           { _error   = null; notifyListeners(); }

  Future<bool> register(String username, String password) async {
    _setLoading(true);
    _setError(null);
    final user = await _db.registerUser(username, password);
    _setLoading(false);
    if (user == null) {
      _setError('ese nombre ya lo uso alguien');
      return false;
    }
    _currentUser = user;
    await _loadCollection();
    await _loadTrades();
    return true;
  }

  Future<bool> login(String username, String password) async {
    _setLoading(true);
    _setError(null);
    final user = await _db.loginUser(username, password);
    _setLoading(false);
    if (user == null) {
      _setError('usuario o contrasena incorrectos');
      return false;
    }
    _currentUser = user;
    await _loadCollection();
    await _loadTrades();
    return true;
  }

  void logout() {
    _currentUser = null;
    _collection  = [];
    _trades      = [];
    _error       = null;
    notifyListeners();
  }

  Future<void> _loadCollection() async {
    if (_currentUser == null) return;
    _collection = await _db.getUserCollection(_currentUser!.id!);
    notifyListeners();
  }

  Future<void> refresh() async {
    await _loadCollection();
    await _loadTrades();
  }

  Future<List<TriviaQuestion>> loadTriviaQuestions() =>
      _poke.generateTriviaQuestions();

  Future<PokemonCollectionModel> awardRandomPokemon() async {
    final entry = await _poke.getRandomPokemonReward(_currentUser!.id!);
    final saved = await _db.addPokemonToCollection(entry);
    _collection = [saved, ..._collection];
    notifyListeners();
    return saved;
  }

  Future<List<UserModel>> getOtherUsers() =>
      _db.getAllUsers(excludeUserId: _currentUser!.id!);

  Future<List<PokemonCollectionModel>> getOtherUserCollection(int userId) =>
      _db.getUserCollection(userId);

  Future<List<PokemonCollectionModel>> getMyTradableCollection() =>
      _db.getUserCollectionExcludingPending(_currentUser!.id!);

  Future<void> _loadTrades() async {
    if (_currentUser == null) return;
    _trades = await _db.getTradesForUser(_currentUser!.id!);
    notifyListeners();
  }

  Future<void> sendTradeOffer({
    required UserModel toUser,
    required PokemonCollectionModel myPokemon,
    required PokemonCollectionModel theirPokemon,
  }) async {
    final trade = TradeModel(
      fromUserId:                   _currentUser!.id!,
      fromUsername:                 _currentUser!.username,
      toUserId:                     toUser.id!,
      toUsername:                   toUser.username,
      offeredPokemonCollectionId:   myPokemon.id!,
      offeredPokemonName:           myPokemon.pokemonName,
      offeredPokemonSprite:         myPokemon.spriteUrl,
      requestedPokemonCollectionId: theirPokemon.id!,
      requestedPokemonName:         theirPokemon.pokemonName,
      requestedPokemonSprite:       theirPokemon.spriteUrl,
      status:                       TradeStatus.pending,
      createdAt:                    DateTime.now(),
    );
    await _db.createTrade(trade);
    await _loadTrades();
  }

  Future<void> acceptTrade(TradeModel trade) async {
    await _db.acceptTrade(trade);
    await _loadCollection();
    await _loadTrades();
  }

  Future<void> rejectTrade(TradeModel trade) async {
    await _db.updateTradeStatus(trade.id!, TradeStatus.rejected);
    await _loadTrades();
  }

  Future<void> cancelTrade(TradeModel trade) async {
    await _db.updateTradeStatus(trade.id!, TradeStatus.cancelled);
    await _loadTrades();
  }

  List<TradeModel> get incomingPendingTrades => _trades
      .where((t) =>
          t.toUserId == _currentUser?.id && t.status == TradeStatus.pending)
      .toList();

  List<TradeModel> get outgoingTrades =>
      _trades.where((t) => t.fromUserId == _currentUser?.id).toList();
}
