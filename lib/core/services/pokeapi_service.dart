import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

import '../models/pokemon_collection_model.dart';

class PokemonData {
  final int id;
  final String name;
  final String spriteUrl;
  final List<String> types;
  final int baseExperience;
  final int height;
  final int weight;
  final List<String> abilities;

  const PokemonData({
    required this.id,
    required this.name,
    required this.spriteUrl,
    required this.types,
    required this.baseExperience,
    required this.height,
    required this.weight,
    required this.abilities,
  });
}

class TriviaQuestion {
  final String question;
  final String correctAnswer;
  final List<String> options;

  const TriviaQuestion({
    required this.question,
    required this.correctAnswer,
    required this.options,
  });
}

class PokeApiService {
  static const String _base = 'https://pokeapi.co/api/v2';
  static const int _totalPokemon = 898;
  final _rng = Random();

  final http.Client _client;
  PokeApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<PokemonData> fetchPokemon(int id) async {
    final res = await _client.get(Uri.parse('$_base/pokemon/$id'));
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch pokemon $id');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return _parsePokemon(json);
  }

  PokemonData _parsePokemon(Map<String, dynamic> json) {
    final id = json['id'] as int;
    final name = (json['name'] as String).capitalize();
    final spriteUrl =
        (json['sprites']['other']['official-artwork']['front_default'] as String?) ??
            (json['sprites']['front_default'] as String? ?? '');
    final types = (json['types'] as List)
        .map((t) => (t['type']['name'] as String).capitalize())
        .toList();
    final abilities = (json['abilities'] as List)
        .map((a) => (a['ability']['name'] as String).capitalize())
        .toList();

    return PokemonData(
      id: id,
      name: name,
      spriteUrl: spriteUrl,
      types: types,
      baseExperience: (json['base_experience'] as int?) ?? 0,
      height: json['height'] as int,
      weight: json['weight'] as int,
      abilities: abilities,
    );
  }

  Future<PokemonCollectionModel> getRandomPokemonReward(int userId) async {
    final id = _rng.nextInt(_totalPokemon) + 1;
    final pokemon = await fetchPokemon(id);
    return PokemonCollectionModel(
      userId: userId,
      pokemonId: pokemon.id,
      pokemonName: pokemon.name,
      spriteUrl: pokemon.spriteUrl,
      types: pokemon.types,
      obtainedAt: DateTime.now(),
    );
  }

  Future<List<TriviaQuestion>> generateTriviaQuestions() async {
    final ids = <int>{};
    while (ids.length < 3) {
      ids.add(_rng.nextInt(_totalPokemon) + 1);
    }
    final pokemonList = await Future.wait(ids.map((id) => fetchPokemon(id)));
    return pokemonList.map((p) => _buildQuestion(p, pokemonList)).toList();
  }

  TriviaQuestion _buildQuestion(PokemonData pokemon, List<PokemonData> pool) {
    final questionType = _rng.nextInt(4);

    switch (questionType) {
      case 0:
        final correct = pokemon.types.first;
        final distractors = _typeDistractors(correct);
        final options = ([correct] + distractors)..shuffle(_rng);
        return TriviaQuestion(
          question: '¿Cuál es el tipo principal de ${pokemon.name}?',
          correctAnswer: correct,
          options: options,
        );

      case 1:
        final correct = pokemon.baseExperience.toString();
        final distractors = List.generate(
            3, (_) => (_rng.nextInt(300) + 20).toString());
        final options = ([correct] + distractors.take(3).toList())
          ..shuffle(_rng);
        return TriviaQuestion(
          question:
              '¿Cuánta experiencia base otorga ${pokemon.name} al ser derrotado?',
          correctAnswer: correct,
          options: options,
        );

      case 2:
        final ability =
            pokemon.abilities.isNotEmpty ? pokemon.abilities.first : 'Overgrow';
        final correct = pokemon.name;
        final others = pool
            .where((p) => p.id != pokemon.id)
            .map((p) => p.name)
            .toList();
        while (others.length < 3) {
          others.add('Missingno');
        }
        final options = ([correct] + others.take(3).toList())..shuffle(_rng);
        return TriviaQuestion(
          question: '¿Qué Pokémon tiene la habilidad "$ability"?',
          correctAnswer: correct,
          options: options,
        );

      default:
        final correct = '${pokemon.weight / 10} kg';
        final distractors = List.generate(
            3, (_) => '${(_rng.nextInt(1000) / 10).toStringAsFixed(1)} kg');
        final options = ([correct] + distractors.take(3).toList())
          ..shuffle(_rng);
        return TriviaQuestion(
          question: '¿Cuánto pesa ${pokemon.name}?',
          correctAnswer: correct,
          options: options,
        );
    }
  }

  static const _allTypes = [
    'Normal', 'Fire', 'Water', 'Electric', 'Grass', 'Ice',
    'Fighting', 'Poison', 'Ground', 'Flying', 'Psychic', 'Bug',
    'Rock', 'Ghost', 'Dragon', 'Dark', 'Steel', 'Fairy',
  ];

  List<String> _typeDistractors(String exclude) {
    final pool = _allTypes.where((t) => t != exclude).toList()..shuffle(_rng);
    return pool.take(3).toList();
  }
}

extension StringCapitalize on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
