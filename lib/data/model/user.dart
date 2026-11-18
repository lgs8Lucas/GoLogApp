/// Usuário logado. Token e senha NÃO ficam aqui: são guardados
/// criptografados pelo [CredentialStore].
class User {
  static const String tableName = 'user';
  static const String columnId = 'id';
  static const String columnName = 'name';
  static const String columnEmail = 'email';
  static const String columnKeepConnected = 'keepConnected';

  final String id;
  final String name;
  final String email;
  final bool keepConnected;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.keepConnected,
  });

  Map<String, dynamic> toDb() {
    return {
      columnId: id,
      columnName: name,
      columnEmail: email,
      columnKeepConnected: keepConnected ? 1 : 0,
    };
  }

  factory User.fromDb(Map<String, dynamic> db) {
    return User(
      id: db[columnId]?.toString() ?? '',
      name: db[columnName] ?? '',
      email: db[columnEmail] ?? '',
      keepConnected: db[columnKeepConnected] == 1,
    );
  }
}
