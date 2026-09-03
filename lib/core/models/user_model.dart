class UserModel {
  final int? id;
  final String username;
  final String passwordHash;
  final String avatarUrl;
  final DateTime createdAt;

  const UserModel({
    this.id,
    required this.username,
    required this.passwordHash,
    required this.avatarUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id':            id,
        'username':      username,
        'password_hash': passwordHash,
        'avatar_url':    avatarUrl,
        'created_at':    createdAt.toIso8601String(),
      };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        id:           map['id'] as int?,
        username:     map['username'] as String,
        passwordHash: map['password_hash'] as String,
        avatarUrl:    map['avatar_url'] as String,
        createdAt:    DateTime.parse(map['created_at'] as String),
      );

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id:           json['id'] as int?,
        username:     json['username'] as String,
        passwordHash: '',
        avatarUrl:    json['avatarUrl'] as String? ??
                      json['avatar_url'] as String? ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'].toString())
            : json['created_at'] != null
                ? DateTime.parse(json['created_at'].toString())
                : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id':        id,
        'username':  username,
        'avatarUrl': avatarUrl,
        'createdAt': createdAt.toIso8601String(),
      };

  UserModel copyWith({int? id}) => UserModel(
        id:           id ?? this.id,
        username:     username,
        passwordHash: passwordHash,
        avatarUrl:    avatarUrl,
        createdAt:    createdAt,
      );
}
