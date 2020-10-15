import 'package:postgres/postgres.dart';

late PostgreSQLConnection db;

Future<PostgreSQLConnection> openDatabase(Map config) async {
  var pg = config['postgresql'];
  db = PostgreSQLConnection(pg['host'], pg['port'], pg['databaseName'],
      username: pg['username'], password: pg['password']);
  await db.open();
  return db;
}
