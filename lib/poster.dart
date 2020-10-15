import 'dart:convert';
import 'dart:core';
import 'dart:math';

import 'package:mustache/mustache.dart';
import 'package:nyxx/nyxx.dart';
import 'package:postgres/postgres.dart';
import 'package:robocore/database.dart';
import 'package:robocore/robocore.dart';

class Field {
  late String label, content;
  Field(this.label, this.content);

  Map<String, dynamic> toJson() {
    return {"label": label, "content": content};
  }

  Field.fromJson(Map<String, dynamic> json) {
    label = json['label'];
    content = json['content'];
  }
}

class Poster {
  late String name;

  /// The numeric id of the Discord channel or Telegram chat
  late int channelOrChatId;

  /// The numeric id of the Poster message
  int messageId = 0;

  // Mandatory
  late String title;

  // Optional
  String? thumbnailUrl, imageUrl;

  /// Time it ends
  late DateTime start, end, revealEnd;

  /// Minutes
  late int updateInterval;
  late int recreateInterval;

  // Alternate content for revealing
  late Map<String, dynamic>? reveal;

  /// Last recreate and update
  DateTime recreated = DateTime(2000);
  DateTime updated = DateTime(2000);

  List<Field> fields = [];

  Snowflake get messageSnowflake => Snowflake(messageId);

  Poster.fromJson(this.name, dynamic json) {
    start = DateTime.parse(json['start']);
    end = DateTime.parse(json['end']);
    revealEnd = DateTime.parse(json['revealEnd']);
    recreateInterval = json['recreate'];
    updateInterval = json['update'];
    channelOrChatId = json['channelId'];
    _readContent(json['content']);
  }

  toJson() {
    Map<String, dynamic> json = {};
    json['start'] = start.toIso8601String();
    json['end'] = end.toIso8601String();
    json['revealEnd'] = revealEnd.toIso8601String();
    json['recreate'] = recreateInterval;
    json['update'] = updateInterval;
    json['channelId'] = channelOrChatId;
    json['content'] = _writeContent();
    return json;
  }

  _readContent(Map json) {
    title = json['title'] ?? title;
    imageUrl = json['imageUrl'] ?? imageUrl;
    thumbnailUrl = json['thumbnailUrl'] ?? thumbnailUrl;
    reveal = json['reveal'] ?? reveal;
    var fs = json['fields'];
    if (fs != null) {
      fields = [];
      for (var field in fs) {
        addField(field['label'], field['content']);
      }
    }
  }

  _writeContent() {
    Map<String, dynamic> json = {};
    json['title'] = title;
    json['imageUrl'] = imageUrl;
    json['thumbnailUrl'] = thumbnailUrl;
    json['reveal'] = reveal;
    json['fields'] = <Map>[];
    var fs = json['fields'];
    if (fields.isNotEmpty) {
      for (var field in fields) {
        fs.add(field.toJson());
      }
    }
    return json;
  }

  addField(String label, content) {
    fields.add(Field(label, content));
  }

  static Future<PostgreSQLResult> dropTable() async {
    return await db.query("drop table if exists _poster;");
  }

  static Future<PostgreSQLResult> createTable() async {
    return await db.query(
        "create table IF NOT EXISTS _poster (name text NOT NULL PRIMARY KEY, info json NOT NULL);");
  }

  Future<void> insert() async {
    posters = null;
    await db.query("INSERT INTO _poster (name, info) VALUES (@name, @info)",
        substitutionValues: {"name": name, "info": toJson()});
  }

  Future<void> delete() async {
    // Invalidate cache
    posters = null;
    await db.query("DELETE FROM _poster where name = @name",
        substitutionValues: {"name": name});
  }

  static List<Poster>? posters;

  static Future<Poster?> find(String name) async {
    var ps = await getAll();
    return ps.firstWhere((p) => p.name == name);
  }

  static Future<List<Poster>> getAll() async {
    if (posters != null) return posters as List<Poster>;
    List<List<dynamic>> results =
        await db.query("SELECT name, info FROM _poster");
    posters = results
        .map((list) => Poster.fromJson(list.first, jsonDecode(list[1])))
        .toList();
    return posters as List<Poster>;
  }

  /// Create (and delete any existing) embed
  recreate(RoboWrapper bot) async {
    deleteMessage(bot);
    var content = build(bot);
    // Send content and store message id
    messageId = await bot.send(channelOrChatId, content) as int;
    recreated = DateTime.now();
  }

  // Delete message
  deleteMessage(RoboWrapper bot) async {
    if (messageId != 0)
      try {
        await bot.deleteMessage(channelOrChatId, messageId);
      } catch (e) {
        log.warning("Failed deleting poster message: $messageId");
      }
  }

  /// Update content of existing embed
  update(RoboWrapper bot) async {
    // If message exists
    // Find embed
    if (messageId != 0)
      try {
        var content = build(bot);
        // Edit it
        await bot.editMessage(channelOrChatId, messageId, content);
        updated = DateTime.now();
      } catch (e) {
        log.warning("Failed updating poster message: $messageId");
      }
  }

  dynamic build(RoboWrapper bot) {
    dynamic result;
    if (bot is RoboDiscordMessage) {
      // Create embed
      result = EmbedBuilder();
      result.title = title;
      if (thumbnailUrl != null) result.thumbnailUrl = thumbnailUrl;
      if (imageUrl != null) result.imageUrl = imageUrl;
      for (var f in fields) {
        var content = merge(f.content, bot);
        result.addField(name: f.label, content: content);
      }
    } else {
      result = "";
    }
    //embed.timestamp = DateTime.now().toUtc();
    return result;
  }

  String toString() => name;

  tick(RoboWrapper bot) {
    try {
      var now = DateTime.now();
      // Are we live yet?
      if (start.isBefore(now)) {
        // Time to delete?
        if (revealEnd.isBefore(now)) {
          log.info("Deleting poster $name");
          deleteMessage(bot);
          delete();
          return;
        }
        // Time to create or recreate?
        if (recreated.add(Duration(minutes: recreateInterval)).isBefore(now)) {
          log.info("Creating or recreating poster $name");
          return recreate(bot);
        }
        // Time to reveal? If so update also
        if (end.isBefore(now) && reveal != null) {
          log.info("Revealing poster $name");
          _readContent(reveal as Map);
          reveal = null; // null out so reveal is only once
          return update(bot);
        }
        // Time to update?
        if (updated.add(Duration(minutes: updateInterval)).isBefore(now)) {
          log.info("Updating poster $name");
          return update(bot);
        }
      }
    } catch (e) {
      log.warning("Failed tick of poster: $e");
    }
  }

  String merge(String template, RoboWrapper bot) {
    var temp = Template(template,
        name: 'test', lenient: false, htmlEscapeValues: false);
    var now = DateTime.now();
    var left = end.difference(now);
    var daysLeft = left.inDays;
    left = left - Duration(days: daysLeft);
    var hoursLeft = left.inHours;
    left = left - Duration(hours: hoursLeft);
    var minutesLeft = left.inMinutes;
    var buf = StringBuffer();
    if (minutesLeft <= 0) {
      buf.write("now");
    } else {
      buf.write("in ");
      if (daysLeft > 0) {
        buf.write("$daysLeft days, ");
      }
      if (hoursLeft > 0) {
        buf.write("$hoursLeft hours, and ");
      }
      if (minutesLeft > 0) {
        buf.write("$minutesLeft minutes");
      }
    }
    var countDown = buf.toString();
    return temp.renderString({
      'countdown': countDown,
      'days': daysLeft,
      'hours': hoursLeft,
      'minutes': minutesLeft,
      'now': now.toIso8601String(),
      'price': bot.bot.priceStringCORE()
    });
  }
}
