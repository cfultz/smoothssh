class Identity {
  final String id;
  final String nickname;
  final String username;
  final String? password;
  final String? privateKey;

  Identity({
    required this.id,
    required this.nickname,
    required this.username,
    this.password,
    this.privateKey,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'nickname': nickname,
    'username': username,
    'password': password,
    'privateKey': privateKey,
  };

  factory Identity.fromJson(Map<String, dynamic> json) => Identity(
    id: json['id'] ?? '',
    nickname: json['nickname'] ?? '',
    username: json['username'] ?? '',
    password: json['password'],
    privateKey: json['privateKey'],
  );
}