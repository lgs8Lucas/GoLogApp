class User {
  static final String tableName = 'user';
  static final String columnId = 'id';
  static final String columnName = 'name';
  static final String columnEmail = 'email';
  static final String columnToken = 'token';
  static final String columnKeepConnected = 'keepConnected';

  final String id;
  final String name;
  final String email;
  final String token;
  final bool keepConnected;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.token,
    required this.keepConnected,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json[columnId],
      name: json[columnName],
      email: json[columnEmail],
      token: json[columnToken],
      keepConnected: true,
    );
  }

  Map<String, dynamic> toDb() {
    return {
      columnId: id,
      columnName: name,
      columnEmail: email,
      columnToken: token,
      columnKeepConnected: keepConnected ? 1 : 0,
    };
  }

  factory User.fromDb(Map<String, dynamic> db) {
    return User(
      id: db[columnId],
      name: db[columnName],
      email: db[columnEmail],
      token: db[columnToken],
      keepConnected: db[columnKeepConnected] == 1,
    );
  }
}
