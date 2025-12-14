class User {
  final int? id;
  final String username;
  final String password;
  final String name;
  final DateTime createdAt;

  User({
    this.id,
    required this.username,
    required this.password,
    required this.name,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      password: map['password'],
      name: map['name'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

