class PokemonCollectionModel {
  final int? id;
  final int userId;
  final int pokemonId;
  final String pokemonName;
  final String spriteUrl;
  final List<String> types;
  final DateTime obtainedAt;

  const PokemonCollectionModel({
    this.id,
    required this.userId,
    required this.pokemonId,
    required this.pokemonName,
    required this.spriteUrl,
    required this.types,
    required this.obtainedAt,
  });

  Map<String, dynamic> toMap() => {
        'id':           id,
        'user_id':      userId,
        'pokemon_id':   pokemonId,
        'pokemon_name': pokemonName,
        'sprite_url':   spriteUrl,
        'types':        types.join(','),
        'obtained_at':  obtainedAt.toIso8601String(),
      };

  factory PokemonCollectionModel.fromMap(Map<String, dynamic> map) =>
      PokemonCollectionModel(
        id:          map['id'] as int?,
        userId:      map['user_id'] as int,
        pokemonId:   map['pokemon_id'] as int,
        pokemonName: map['pokemon_name'] as String,
        spriteUrl:   map['sprite_url'] as String,
        types:       (map['types'] as String).split(','),
        obtainedAt:  DateTime.parse(map['obtained_at'] as String),
      );

  factory PokemonCollectionModel.fromJson(Map<String, dynamic> json) {
    List<String> parseTypes(dynamic raw) {
      if (raw is List) return raw.map((e) => e.toString()).toList();
      if (raw is String) return raw.split(',');
      return [];
    }

    return PokemonCollectionModel(
      id:          json['id'] as int?,
      userId:      (json['userId'] ?? json['user_id']) as int,
      pokemonId:   (json['pokemonId'] ?? json['pokemon_id']) as int,
      pokemonName: (json['pokemonName'] ?? json['pokemon_name']) as String,
      spriteUrl:   (json['spriteUrl'] ?? json['sprite_url']) as String,
      types:       parseTypes(json['types']),
      obtainedAt:  json['obtainedAt'] != null
          ? DateTime.parse(json['obtainedAt'].toString())
          : json['obtained_at'] != null
              ? DateTime.parse(json['obtained_at'].toString())
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id':          id,
        'userId':      userId,
        'pokemonId':   pokemonId,
        'pokemonName': pokemonName,
        'spriteUrl':   spriteUrl,
        'types':       types,
        'obtainedAt':  obtainedAt.toIso8601String(),
      };
}
