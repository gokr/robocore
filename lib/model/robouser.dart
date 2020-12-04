import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:robocore/chat/robomessage.dart';
import 'package:robocore/database.dart';

class RoboUser {
  int? id;
  String? discordId, telegramId;
  late String username;
  String? nickname;
  DateTime created = DateTime.now().toUtc();

  RoboUser(this.id, this.discordId, this.telegramId, this.created);
  RoboUser.discord(this.discordId);
  RoboUser.telegram(this.telegramId);
  RoboUser.both(this.discordId, this.telegramId, this.username, this.nickname);

  RoboUser.fromDb(this.id, this.discordId, this.telegramId, this.username,
      this.nickname, this.created, dynamic json) {
    // Pick out stuff from json
    readJson(json);
  }

  String get name => nickname ?? username;

  writeJson() {
    Map<String, dynamic> json = {};
    // json['xxx'] = start.toIso8601String();
    return json;
  }

  readJson(Map json) {}

  @override
  bool operator ==(other) {
    if (other is RoboUser)
      return other.discordId == this.discordId ||
          other.telegramId == this.telegramId;
    return false;
  }

  static Future<PostgreSQLResult> dropTable() async {
    return await db.query("drop table if exists _robouser;");
  }

  static Future<PostgreSQLResult> createTable() async {
    return await db.query(
        "create table IF NOT EXISTS _robouser (id integer GENERATED ALWAYS AS IDENTITY, PRIMARY KEY(id), created timestamp, discordid integer, telegramid integer, username text, nickname text, info json NOT NULL);");
  }

  Future<void> update() async {
    await db.query(
        "UPDATE _robouser set created = @created, discordid = @discordid, telegramid = @telegramid, username = @username, nickname = @nickname, info = @info where id = @id",
        substitutionValues: {
          "id": id,
          "created": created.toIso8601String(),
          "discordid": discordId,
          "telegramid": telegramId,
          "username": username,
          "nickname": nickname,
          "info": writeJson()
        });
  }

  Future<void> insert() async {
    await db.query(
        "INSERT INTO _robouser (created, discordid, telegramid, username, nickname, info) VALUES (@created, @discordid, @telegramid, @username, @nickname, @info)",
        substitutionValues: {
          "created": created.toIso8601String(),
          "discordid": discordId,
          "telegramid": telegramId,
          "username": username,
          "nickname": nickname,
          "info": writeJson()
        });
  }

  static Future<RoboUser?> findUser({String? discordId, telegramId}) async {
    List<List<dynamic>> results;
    if (discordId != null) {
      results = await db.query(
          "SELECT id, discordId, telegramId, username, nickname, created, info  FROM _robouser where discordId = @discordId",
          substitutionValues: {"discordId": discordId});
    } else {
      results = await db.query(
          "SELECT id, discordId, telegramId, username, nickname, created, info  FROM _robouser where telegramId = @telegramId",
          substitutionValues: {"telegramId": telegramId});
    }
    if (results.isNotEmpty) {
      var list = results.first;
      return RoboUser.fromDb(list[0], list[1], list[2], list[3], list[4],
          list[5], jsonDecode(list[6]));
    }
  }

  static Future<RoboUser> findOrCreateUser(
      {String? discordId,
      telegramId,
      required String username,
      String? nickname}) async {
    var user = await findUser(discordId: discordId, telegramId: telegramId);
    if (user == null) {
      // Then we create one
      user = RoboUser.both(discordId, telegramId, username, nickname);
      await user.insert();
      // Reload to get id
      user =
          await RoboUser.findUser(discordId: discordId, telegramId: telegramId);
    }
    return user!;
  }

  static Future<List<RoboUser>> getAllUsers() async {
    List<List<dynamic>> results = await db.query(
        "SELECT id, discordId, telegramId, username, nickname, created, info  FROM _robouser");
    return results.map((list) {
      return RoboUser.fromDb(list[0], list[1], list[2], list[3], list[4],
          list[5], jsonDecode(list[6]));
    }).toList();
  }

  static Future<List<RoboUser>> findFuzzyUsers(String name) async {
    var query =
        "SELECT id, discordId, telegramId, username, nickname, created, info  FROM _robouser where levenshtein(@attribute, @value) <= 3 ORDER BY levenshtein(@attribute, @value) LIMIT 10";
    var results = await db.query(query,
        substitutionValues: {"attribute": "username", "value": name});
    var users1 = usersFromResults(results);
    results = await db.query(query,
        substitutionValues: {"attribute": "nickname", "value": name});
    var users2 = usersFromResults(results);
    return users1 + users2;
  }

  static List<RoboUser> usersFromResults(List<List<dynamic>> results) {
    return results.map((list) {
      return RoboUser.fromDb(list[0], list[1], list[2], list[3], list[4],
          list[5], jsonDecode(list[6]));
    }).toList();
  }

  String toString() => "RoboUser<$username>($discordId, $telegramId)";
}
