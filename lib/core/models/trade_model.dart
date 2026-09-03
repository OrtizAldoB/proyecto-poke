enum TradeStatus { pending, accepted, rejected, cancelled }

class TradeModel {
  final int? id;
  final int fromUserId;
  final String fromUsername;
  final int toUserId;
  final String toUsername;
  final int offeredPokemonCollectionId;
  final String offeredPokemonName;
  final String offeredPokemonSprite;
  final int requestedPokemonCollectionId;
  final String requestedPokemonName;
  final String requestedPokemonSprite;
  final TradeStatus status;
  final DateTime createdAt;

  const TradeModel({
    this.id,
    required this.fromUserId,
    required this.fromUsername,
    required this.toUserId,
    required this.toUsername,
    required this.offeredPokemonCollectionId,
    required this.offeredPokemonName,
    required this.offeredPokemonSprite,
    required this.requestedPokemonCollectionId,
    required this.requestedPokemonName,
    required this.requestedPokemonSprite,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id':                              id,
        'from_user_id':                    fromUserId,
        'from_username':                   fromUsername,
        'to_user_id':                      toUserId,
        'to_username':                     toUsername,
        'offered_pokemon_collection_id':   offeredPokemonCollectionId,
        'offered_pokemon_name':            offeredPokemonName,
        'offered_pokemon_sprite':          offeredPokemonSprite,
        'requested_pokemon_collection_id': requestedPokemonCollectionId,
        'requested_pokemon_name':          requestedPokemonName,
        'requested_pokemon_sprite':        requestedPokemonSprite,
        'status':                          status.name,
        'created_at':                      createdAt.toIso8601String(),
      };

  factory TradeModel.fromMap(Map<String, dynamic> map) => TradeModel(
        id:           map['id'] as int?,
        fromUserId:   map['from_user_id'] as int,
        fromUsername: map['from_username'] as String,
        toUserId:     map['to_user_id'] as int,
        toUsername:   map['to_username'] as String,
        offeredPokemonCollectionId:
            map['offered_pokemon_collection_id'] as int,
        offeredPokemonName:   map['offered_pokemon_name'] as String,
        offeredPokemonSprite: map['offered_pokemon_sprite'] as String,
        requestedPokemonCollectionId:
            map['requested_pokemon_collection_id'] as int,
        requestedPokemonName:   map['requested_pokemon_name'] as String,
        requestedPokemonSprite: map['requested_pokemon_sprite'] as String,
        status:    TradeStatus.values.byName(map['status'] as String),
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  factory TradeModel.fromJson(Map<String, dynamic> json) {
    int pickInt(String camel, String snake) =>
        (json[camel] ?? json[snake]) as int;
    String pickStr(String camel, String snake) =>
        (json[camel] ?? json[snake]) as String;

    return TradeModel(
      id:           json['id'] as int?,
      fromUserId:   pickInt('fromUserId',   'from_user_id'),
      fromUsername: pickStr('fromUsername', 'from_username'),
      toUserId:     pickInt('toUserId',     'to_user_id'),
      toUsername:   pickStr('toUsername',   'to_username'),
      offeredPokemonCollectionId:
          pickInt('offeredPokemonCollectionId', 'offered_pokemon_collection_id'),
      offeredPokemonName:
          pickStr('offeredPokemonName', 'offered_pokemon_name'),
      offeredPokemonSprite:
          pickStr('offeredPokemonSprite', 'offered_pokemon_sprite'),
      requestedPokemonCollectionId:
          pickInt('requestedPokemonCollectionId', 'requested_pokemon_collection_id'),
      requestedPokemonName:
          pickStr('requestedPokemonName', 'requested_pokemon_name'),
      requestedPokemonSprite:
          pickStr('requestedPokemonSprite', 'requested_pokemon_sprite'),
      status: TradeStatus.values.byName(json['status'] as String),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : json['created_at'] != null
              ? DateTime.parse(json['created_at'].toString())
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id':                              id,
        'fromUserId':                      fromUserId,
        'fromUsername':                    fromUsername,
        'toUserId':                        toUserId,
        'toUsername':                      toUsername,
        'offeredPokemonCollectionId':      offeredPokemonCollectionId,
        'offeredPokemonName':              offeredPokemonName,
        'offeredPokemonSprite':            offeredPokemonSprite,
        'requestedPokemonCollectionId':    requestedPokemonCollectionId,
        'requestedPokemonName':            requestedPokemonName,
        'requestedPokemonSprite':          requestedPokemonSprite,
        'status':                          status.name,
        'createdAt':                       createdAt.toIso8601String(),
      };

  TradeModel copyWith({TradeStatus? status}) => TradeModel(
        id:                              id,
        fromUserId:                      fromUserId,
        fromUsername:                    fromUsername,
        toUserId:                        toUserId,
        toUsername:                      toUsername,
        offeredPokemonCollectionId:      offeredPokemonCollectionId,
        offeredPokemonName:              offeredPokemonName,
        offeredPokemonSprite:            offeredPokemonSprite,
        requestedPokemonCollectionId:    requestedPokemonCollectionId,
        requestedPokemonName:            requestedPokemonName,
        requestedPokemonSprite:          requestedPokemonSprite,
        status:    status ?? this.status,
        createdAt: createdAt,
      );
}
