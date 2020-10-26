import 'dart:convert';

import 'package:robocore/chat/robomessage.dart';
import 'package:robocore/commands/command.dart';
import 'package:robocore/model/poster.dart';
import 'package:robocore/util.dart';

class PosterCommand extends Command {
  PosterCommand()
      : super("poster", "", "poster [add|remove] \"name\" {...json...}",
            """Manage dynamic posters. On Telegram implemented as a live updated pinned message, on Discord as a live updated regularly reposted message.
            This command is only available to specific admin users.""");

  @override
  handleMessage(RoboMessage bot) async {
    // All posters
    var posters = await Poster.getAll();
    var parts = bot.parts;
    // poster list = Shows all posters
    // poster remove xxx = removes a named poster
    /* !poster add zzz '{"channelId": 762629759393726464, "start": "2020-10-15T02:20:12","end": "2020-10-15T02:35:12",
      "revealEnd": "2020-10-15T02:37:12", "recreate": 2, "update": 1, "content":
      {"reveal": {"imageUrl": "http://rey.krampe.se/whale2.jpg", "fields": [{"label":
      "What", "content": "Party is starting!!"},{"label":"Where","content":"<a href=\"http://goran.krampe.se\">here</a>"}]},
      "imageUrl":"http://rey.krampe.se/whale1.jpg", "title": "Whale hunting",
      "fields": [{"label": "What", "content": "Party!!"},{"label": "When", "content": "... happening {{countdown}}"}]}}' */
    if (parts.length == 1) {
      if (posters.isEmpty) {
        return await bot.reply("No active posters");
      }
      String allPosters = posters.join(" ");
      return await bot.reply("Active posters: $allPosters");
    }
    if (parts.length == 2) {
      return await bot.reply("Use add|remove ...");
    }
    if (parts.length < 3) {
      return await bot.reply("Too few arguments");
    }
    if (!["add", "remove"].contains(parts[1])) {
      return await bot.reply("Use add|remove");
    }
    bool add = parts[1] == "add";
    var name = parts[2];
    // Remove?
    if (!add) {
      var poster = await Poster.find(name);
      if (poster != null) {
        poster.deleteMessages(bot);
        poster.delete();
        return await bot.reply("Removed poster $name");
      } else {
        return await bot.reply("Could not find poster $name");
      }
    }

    // Create a Poster
    try {
      var json = jsonDecode(trimQuotes(parts[3]));
      var poster = Poster.fromJson(name, json);
      await poster.insert();
    } catch (e) {
      return await bot.reply("Failed: $e");
    }
  }
}
