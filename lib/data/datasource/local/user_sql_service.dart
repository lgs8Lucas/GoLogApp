import 'package:golog/data/model/user.dart';
import 'package:sqflite/sqflite.dart';

class UserSqlService {
  final Database _db;

  UserSqlService(this._db);

  /// Usuário logado (o app guarda no máximo um).
  Future<User?> getCurrentUser() async {
    final rows = await _db.query(User.tableName, limit: 1);
    return rows.isEmpty ? null : User.fromDb(rows.first);
  }

  Future<String> getCurrentUserId() async => (await getCurrentUser())?.id ?? '';

  /// Substitui o usuário salvo pelo [user].
  Future<void> replaceUser(User user) async {
    await _db.transaction((txn) async {
      await txn.delete(User.tableName);
      await txn.insert(User.tableName, user.toDb());
    });
  }

  Future<int> deleteAllUsers() => _db.delete(User.tableName);
}
