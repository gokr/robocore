import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:robocore/chat/discordchannel.dart';
import 'package:robocore/chat/robochannel.dart';
import 'package:robocore/chat/telegramchannel.dart';
import 'package:robocore/ethereum.dart';
import 'package:robocore/pair.dart';
import 'package:robocore/robocore.dart';
import 'package:robocore/database.dart';
import 'package:robocore/model/swap.dart';

class EventLogger {
  late int id;

  late String name;
  Pair pair;
  RoboChannel channel;

  EventLogger(this.name, this.pair, this.channel);

/*  static EventLogger fromDb(Ethereum ethereum, int id, String name, int type,
      int pairId, int? discordChannelId, int? telegramChatID, dynamic json) {
    var pair = ethereum.findPairById(pairId);
    var channel =
        (discordChannelId != null) ? DiscordChannel(id) : TelegramChannel(id);
    switch (type) {
    }
    readJson(json);
  }
*/
  writeJson() {
    Map<String, dynamic> json = {};
    return json;
  }

  readJson(Map json) {}

  log(Robocore bot, Swap swap) async {}

  static Future<PostgreSQLResult> dropTable() async {
    return await db.query("drop table if exists _logger;");
  }

  static Future<PostgreSQLResult> createTable() async {
    return await db.query(
        "create table IF NOT EXISTS _logger (id integer GENERATED ALWAYS AS IDENTITY, PRIMARY KEY(id), name text NOT NULL, pair integer, channel integer, info json NOT NULL);");
  }

  Future<void> insert() async {
    // Invalidate cache
    loggers = [];
    await db.query("INSERT INTO _logger (name, info) VALUES (@name, @info)",
        substitutionValues: {"name": name, "info": writeJson()});
  }

  Future<void> delete() async {
    // Invalidate cache
    loggers = [];
    await db.query("DELETE FROM _logger where id = @id",
        substitutionValues: {"id": id});
  }

  static List<EventLogger> loggers = [];

  static Future<EventLogger?> find(String name, int channelId) async {
    var ps = []; //await getAll();
    return ps.firstWhere((p) => p.name == name && p.channel.id == channelId);
  }

  /*static Future<List<EventLogger>> getAll() async {
    // Cached
    if (loggers.isNotEmpty) return loggers;
    List<List<dynamic>> results =
        await db.query("SELECT id, name, pair, channelId, info FROM _logger");
    loggers = results
        .map((list) => EventLogger.fromDb(
            list[0], list[1], list[2], list[3], jsonDecode(list[3])))
        .toList() as List<EventLogger>;
    return loggers;
  }*/

  String toString() => "$name($pair)";

  bool operator ==(o) => o is EventLogger && name == o.name;

  int get hashCode => name.hashCode;
}
