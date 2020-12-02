import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:robocore/chat/robomessage.dart';
import 'package:robocore/database.dart';

class RoboUser {
  late int id;
  String? discordId, telegramId;
  DateTime created = DateTime.now().toUtc();

  late String username;

  RoboUser(this.id, this.discordId, this.telegramId, this.created);
  RoboUser.discord(this.discordId);
  RoboUser.telegram(this.telegramId);
  RoboUser.both(this.discordId, this.telegramId, this.username);

  RoboUser.fromDb(this.id, this.discordId, this.telegramId, this.username,
      this.created, dynamic json) {
    // Pick out stuff from json
    readJson(json);
  }

  writeJson() {
    Map<String, dynamic> json = {};
    // json['xxx'] = start.toIso8601String();
    return json;
  }

  bool isImpostor(RoboMessage msg) {
    if (username == 'gokr') {
      return true;
    }
    return false; // TODO: Perform lookup and verify nick
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
        "create table IF NOT EXISTS _robouser (id integer GENERATED ALWAYS AS IDENTITY, PRIMARY KEY(id), created timestamp, discordid integer, telegramid integer, username text, info json NOT NULL);");
  }

  Future<void> update() async {
    await db.query(
        "UPDATE _robouser set created = @created, discordid = @discordid, telegramid = @telegramid, username = @username, info = @info where id = @id",
        substitutionValues: {
          "id": id,
          "created": created.toIso8601String(),
          "discordid": discordId,
          "telegramid": telegramId,
          "username": username,
          "info": writeJson()
        });
  }

  Future<void> insert() async {
    await db.query(
        "INSERT INTO _robouser (created, discordid, telegramid, username, info) VALUES (@created, @discordid, @telegramid, @username, @info)",
        substitutionValues: {
          "created": created.toIso8601String(),
          "discordid": discordId,
          "telegramid": telegramId,
          "username": username,
          "info": writeJson()
        });
  }

  static Future<RoboUser?> findUser({String? discordId, telegramId}) async {
    List<List<dynamic>> results;
    if (discordId != null) {
      results = await db.query(
          "SELECT id, discordId, telegramId, username, created, info  FROM _robouser where discordId = @discordId",
          substitutionValues: {"discordId": discordId});
    } else {
      results = await db.query(
          "SELECT id, discordId, telegramId, username, created, info  FROM _robouser where telegramId = @telegramId",
          substitutionValues: {"telegramId": telegramId});
    }
    if (results.isNotEmpty) {
      var list = results.first;
      return RoboUser.fromDb(
          list[0], list[1], list[2], list[3], list[4], jsonDecode(list[5]));
    }
  }

  static Future<RoboUser> findOrCreateUser(
      {String? discordId, telegramId, required String username}) async {
    var user = await findUser(discordId: discordId, telegramId: telegramId);
    if (user == null) {
      // Then we create one
      user = RoboUser.both(discordId, telegramId, username);
      await user.insert();
      // Reload to get id
      user =
          await RoboUser.findUser(discordId: discordId, telegramId: telegramId);
    }
    return user!;
  }

  static Future<List<RoboUser>> getAllUsers() async {
    List<List<dynamic>> results = await db.query(
        "SELECT id, discordId, telegramId, username, created, info  FROM _robouser");
    return results.map((list) {
      return RoboUser.fromDb(
          list[0], list[1], list[2], list[3], list[4], jsonDecode(list[5]));
    }).toList();
  }

  String toString() => "RoboUser<$username>($discordId, $telegramId)";
}
