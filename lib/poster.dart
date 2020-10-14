import 'dart:core';
import 'dart:math';

import 'package:mustache/mustache.dart';
import 'package:nyxx/nyxx.dart';
import 'package:robocore/robocore.dart';

class Field {
  late String name, content;
  Field(this.name, this.content);
}

class Poster {
  late String name;
  late Map<String, dynamic> reveal;
  late int channelId;

  late String title;
  String? thumbnailUrl;
  String? imageUrl;

  /// Time it ends
  late DateTime end;
  late DateTime revealEnd;

  /// Minutes
  late int updateInterval;
  late int recreateInterval;

  /// Last recreate and update
  DateTime recreated = DateTime(2000);
  DateTime updated = DateTime(2000);

  List<Field> fields = [];

  Snowflake messageId = Snowflake(0);

  Poster.fromJson(this.name, dynamic json) {
    end = DateTime.parse(json['end']);
    revealEnd = DateTime.parse(json['revealEnd']);
    recreateInterval = json['recreate'];
    updateInterval = json['update'];
    channelId = json['channelId'];
    _readContent(json['content']);
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

  addField(String name, content) {
    fields.add(Field(name, content));
  }

  /// Create (and delete any existing) embed
  recreate(Robocore bot) async {
    delete(bot);
    var embed = build(bot);
    var channel = await bot.getChannel(channelId);
    // Send embed and store message id
    messageId = (await channel.send(embed: embed)).id;
    recreated = DateTime.now();
  }

  // Delete message
  delete(Robocore bot) async {
    if (messageId != 0)
      try {
        var channel = await bot.getChannel(channelId);
        var oldMessage = await channel.getMessage(messageId);
        if (oldMessage != null) {
          // Delete it
          await oldMessage.delete();
        }
      } catch (e) {
        log.warning("Failed deleting poster message: $messageId");
      }
  }

  /// Update content of existing embed
  update(Robocore bot) async {
    // If message exists
    // Find embed
    if (messageId != 0)
      try {
        var channel = await bot.getChannel(channelId);
        var oldMessage = await channel.getMessage(messageId);
        if (oldMessage == null) {
          log.warning("Oops, missing poster!");
          return;
        }
        var embed = build(bot);
        // Edit it
        oldMessage.edit(embed: embed);
        updated = DateTime.now();
      } catch (e) {
        log.warning("Failed updating poster message: $messageId");
      }
  }

  EmbedBuilder build(Robocore bot) {
    // Create embed
    var embed = EmbedBuilder();
    embed.title = title;
    if (thumbnailUrl != null) embed.thumbnailUrl = thumbnailUrl;
    if (imageUrl != null) embed.imageUrl = imageUrl;
    for (var f in fields) {
      var content = merge(f.content, bot);
      embed.addField(name: f.name, content: content);
    }
    //embed.timestamp = DateTime.now().toUtc();
    return embed;
  }

  String toString() => name;

  tick(Robocore bot) {
    print("tick");
    try {
      var now = DateTime.now();
      // Time to delete?
      if (revealEnd.isBefore(now)) {
        print("Delete");
        delete(bot);
        bot.removePoster(name, channelId);
        return;
      }
      // Time to end and reveal?
      if (end.isBefore(now)) {
        print("Reveal");
        _readContent(reveal);
        return update(bot);
      }
      // Time to recreate?
      if (recreated.add(Duration(minutes: recreateInterval)).isBefore(now)) {
        print("Recreate");
        return recreate(bot);
      }
      // Time to update?
      if (updated.add(Duration(minutes: updateInterval)).isBefore(now)) {
        print("Update");
        return update(bot);
      }
    } catch (e) {
      log.warning("Failed tick of poster: $e");
    }
  }

  String merge(String template, Robocore bot) {
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
      'price': bot.priceStringCORE()
    });
  }
}
