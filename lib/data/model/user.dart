class User {
  static final String tableName = 'user';
  static final String columnId = 'id';
  static final String columnName = 'name';
  static final String columnEmail = 'email';

  final String id;
  final String name;
  final String email;

  User({required this.id, required this.name, required this.email});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json[columnId],
      name: json[columnName],
      email: json[columnEmail],
    );
  }
}
