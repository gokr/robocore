import 'dart:convert';
import 'dart:math';

import 'package:nyxx/nyxx.dart';
import 'package:robocore/core.dart';
import 'package:robocore/event_logger.dart';
import 'package:robocore/poster.dart';
import 'package:robocore/robocore.dart';

const discordPrefix = "!";
const telegramPrefix = "/";

// Hacky, but ok
String trimQuotes(String s) {
  var trimmed = s;
  if (s.startsWith("'")) {
    trimmed = s.substring(1);
  }
  if (trimmed.endsWith("'")) {
    return trimmed.substring(0, trimmed.length - 1);
  }
  return trimmed;
}

abstract class Command {
  String name, short, syntax, help;
  List<int> blacklist = [];
  List<int> whitelist = [];

  Command(this.name, this.short, this.syntax, this.help);

  /// Handle the command, returns true if handled
  Future<bool> exec(RoboWrapper bot);

  /// Handle the command, returns a String if handled, otherwise null
  Future<String?> inlineTelegram(String cmd, Robocore robot) async {
    return null;
  }

  // Either whitelisted or blacklisted (can't be both). DMs are fine.
  bool listChecked(MessageReceivedEvent e) {
    if (e.message.channel.type == ChannelType.dm) return true;
    return listCheckedChannel(e.message.channel);
  }

  bool listCheckedChannel(ITextChannel channel) {
    if (whitelist.isNotEmpty) {
      return whitelist.contains(channel.id.id);
    } else {
      return !blacklist.contains(channel.id.id);
    }
  }

  bool availableIn(ITextChannel channel) {
    return listCheckedChannel(channel);
  }

  String get command => "$discordPrefix$name";
  String get shortCommand => "$discordPrefix$short";
}

class HelpCommand extends Command {
  HelpCommand(name, short, syntax, help) : super(name, short, syntax, help);

  @override
  Future<bool> exec(RoboWrapper bot) async {
    await bot.reply(bot.buildHelp());
    return true;
  }
}

class PosterCommand extends Command {
  PosterCommand(name, short, syntax, help) : super(name, short, syntax, help);

  @override
  Future<bool> exec(RoboWrapper bot) async {
    if (bot is RoboDiscord) {
      var chId = bot.e.message.channel.id.id;
      var posters = bot.bot.posters.where((p) => p.channelId == chId);
      var parts = bot.parts;
      // poster = shows posters
      // poster remove xxx = removes a named poster
      // poster add xxx '{"channel": "end": "2020-10-29T12:12:12", "recreate": 20, "update": 1,
      // "title": "LGE 2 is coming!", "image": "aURL", "thumbnail": "aURL", "fields": [{"label": "Countdown", "content": "{{timer}}"}]}'
      if (parts.length == 1) {
        String active = posters.join(" ");
        await bot.reply("Active posters: $active");
        return true;
      }
      if (parts.length == 2) {
        await bot.reply("Use add|remove");
        return true;
      }
      if (parts.length < 3) {
        await bot.reply("Too few arguments");
        return true;
      }

      if (!["add", "remove"].contains(parts[1])) {
        await bot.reply("Use add|remove");
        return true;
      }
      bool add = parts[1] == "add";
      var name = parts[2];
      if (!add) {
        bot.bot.removePoster(name, chId);
        await bot.reply("Removed poster $name");
        return true;
      }

      // Create a Poster

      try {
        var json = jsonDecode(trimQuotes(parts[3]));
        var poster = Poster.fromJson(name, json);
        bot.bot.addPoster(poster);
      } catch (e) {
        await bot.reply("Failed: $e");
        return true;
      }
    } else {
      await bot.reply("Working on it!");
    }
    return false;
  }
}

/*
class StickyCommand extends Command {
  StickyCommand(name, short, syntax, help) : super(name, short, syntax, help);

  @override
  Future<bool> execDiscord(MessageReceivedEvent e, Robocore robot) async {
    if (_validDiscord(e)) {
      _logDiscordCommand(e);
      var parts = splitMessage(e);
      String? name, sticky;
      // Only !sticky
      if (parts.length == 1) {
        await e.message.channel.send(
            content: "Use for example !sticky mysticky \"Yaddayadd, blabla\"");
        return true;
      }
      // Also name given
      if (parts.length == 2) {
        await e.message.channel.send(
            content: "Use for example !sticky mysticky \"Yaddayadd, blabla\"");
        return true;
      } else {
        name = parts[2];
        sticky = parts[3];
        // Remove "" around sticky
        if (sticky.startsWith("\"")) {
          sticky = sticky.substring(1, sticky.length - 1);
        }
      }
      // Create or update sticky with name
      var snowflake = robot.stickies[name];
      if (snowflake != null) {
        var sticky = await e.message.channel.getMessage(snowflake);
      } else {
        // Create it
        Message()
        await e.message.channel.send(
            content: "No sticky called $name found");
        return true;
      }
      sticky.
      return true;
    }
    return false;
  }

  @override
  Future<bool> execTelegram(TeleDartMessage message, Robocore robot) async {
    if (_validTelegram(message)) {
      await message.reply("not yet fixed for Telegram");
      return true;
    }
    return false;
  }
}
*/
class PriceCommand extends Command {
  PriceCommand(name, short, syntax, help) : super(name, short, syntax, help);

  @override
  Future<bool> exec(RoboWrapper bot) async {
    await bot.bot.updatePriceInfo();
    var parts = bot.parts;
    String? coin, amountString;
    num amount = 1;
    // Only !p or !price
    if (parts.length == 1) {
      dynamic answer;
      if (bot is RoboDiscord) {
        answer = EmbedBuilder()
          ..addAuthor((author) {
            author.name = "Prices fresh directly from contracts";
            //author.iconUrl = e.message.author.avatarURL();
          })
          ..addField(name: "Price CORE", content: bot.bot.priceStringCORE())
          ..addField(name: "Price ETH", content: bot.bot.priceStringETH())
          ..addField(name: "Price LP", content: bot.bot.priceStringLP())
          ..timestamp = DateTime.now().toUtc()
          ..color = bot.color();
      } else {
        answer = """
<b>Price CORE:</b> ${bot.bot.priceStringCORE()}
<b>Price ETH:</b> ${bot.bot.priceStringETH()}
<b>Price LP:</b> ${bot.bot.priceStringLP()}
""";
      }
      await bot.reply(answer);
      return true;
    }
    // Also coin given
    if (parts.length == 2) {
      coin = parts[1];
    } else {
      coin = parts[2];
      amountString = parts[1];
    }
    // Check valid coins
    if (!["core", "eth", "lp"].contains(coin)) {
      await bot.reply("Coin can be core, eth or lp, not \"$coin\"");
      return true;
    }
    // Parse amount as num
    if (amountString != null) {
      try {
        amount = num.parse(amountString);
      } catch (ex) {
        await bot.reply(
            "Amount not a number: ${parts[2]}. Use for example \"!p 10 core\"");
        return true;
      }
    }
    // Time to answer
    switch (coin) {
      case "core":
        await bot.reply(bot.bot.priceStringCORE(amount));
        break;
      case "eth":
        await bot.reply(bot.bot.priceStringETH(amount));
        break;
      case "lp":
        await bot.reply(bot.bot.priceStringLP(amount));
        break;
    }
    return true;
  }

  /// Handle the command, returns true if handled
  /*Future<String?> inlineTelegram(String cmd, Robocore robot) async {
    if (_validTelegramCommand(cmd)) {
      return robot.priceStringCORE(1);
    }
  }*/
}

class FloorCommand extends Command {
  FloorCommand(name, short, syntax, help) : super(name, short, syntax, help);

  @override
  Future<bool> exec(RoboWrapper bot) async {
    dynamic answer;
    await bot.bot.updatePriceInfo();
    if (bot is RoboDiscord) {
      answer = EmbedBuilder()
        ..addAuthor((author) {
          author.name = "Floor prices calculated from contracts";
          //author.iconUrl = e.message.author.avatarURL();
        })
        ..addField(
            name: "Floor CORE",
            content:
                "1 CORE = ${usd2(bot.bot.floorCOREinUSD)} (${dec4(bot.bot.floorCOREinETH)} ETH)")
        ..addField(
            name: "Floor LP",
            content:
                "1 LP = ${usd2(bot.bot.floorLPinUSD)} (${dec4(bot.bot.floorLPinETH)} ETH)")
        ..timestamp = DateTime.now().toUtc()
        ..color = bot.color();
    } else {
      answer = """
<b>Floor CORE</b>
1 CORE = ${usd2(bot.bot.floorCOREinUSD)} (${dec4(bot.bot.floorCOREinETH)} ETH)
<b>Floor LP</b>
1 LP = ${usd2(bot.bot.floorLPinUSD)} (${dec4(bot.bot.floorLPinETH)} ETH)
""";
    }
    await bot.reply(answer);
    return true;
  }

  /// Handle the command, returns true if handled
  /*
  Future<String?> inlineTelegram(String cmd, Robocore robot) async {
    if (_validTelegramCommand(cmd)) {
      return robot.floorStringCORE(1);
    }
  }*/
}

class FAQCommand extends Command {
  FAQCommand(name, short, syntax, help) : super(name, short, syntax, help);

  @override
  Future<bool> exec(RoboWrapper bot) async {
    dynamic answer;
    if (bot is RoboDiscord) {
      answer = EmbedBuilder()
        ..addAuthor((author) {
          author.name = "Various links to good info";
        })
        ..addField(name: "FAQ", content: "https://help.cvault.finance/faqs/faq")
        ..addField(
            name: "Vision article",
            content:
                "https://medium.com/@0xdec4f/the-idea-project-and-vision-of-core-vault-52f5eddfbfb")
        ..addFooter((footer) {
          footer.text = "Keep HODLING";
        })
        ..color = bot.color();
    } else {
      answer = """
<b>FAQ</b>
https://help.cvault.finance/faqs/faq
<b>Vision article</b>
https://medium.com/@0xdec4f/the-idea-project-and-vision-of-core-vault-52f5eddfbfb
""";
    }
    bot.reply(answer);
    return true;
  }
}

class StartCommand extends Command {
  StartCommand(name, short, syntax, help) : super(name, short, syntax, help);

  @override
  Future<bool> exec(RoboWrapper bot) async {
    bot.reply("Well, hi there ${bot.sender()}! What can I do for you?");
    return true;
  }
}

class LogCommand extends Command {
  LogCommand(name, short, syntax, help) : super(name, short, syntax, help);

  @override
  Future<bool> exec(RoboWrapper w) async {
    if (w is RoboDiscord) {
      var bot = w.bot;
      var ch = w.e.message.channel;
      var parts = w.parts;
      var loggers = w.bot.loggers.where((logger) => logger.channel == ch);
      // log = shows loggers
      // log remove all = removes all
      // log add|remove xxx = adds or removes logger

      // "log"
      if (parts.length == 1) {
        String active = loggers.join(" ");
        await w.reply("Active loggers: $active");
        return true;
      }
      if (parts.length == 2) {
        await w.reply("Use add|remove [whale|swap|price|all]");
        return true;
      }
      if (parts.length >= 3) {
        if (!["add", "remove"].contains(parts[1])) {
          await w.reply("Use add|remove [whale|swap|price|all]");
          return true;
        }
        bool add = parts[1] == "add";
        var names = parts.sublist(2);
        for (var name in names) {
          switch (name) {
            case "whale":
              if (add) {
                bot.addLogger(WhaleLogger("whale", ch));
              } else {
                bot.removeLogger("whale", ch);
              }
              break;
            case "price":
              if (add) {
                bot.addLogger(PriceLogger("price", ch));
              } else {
                bot.removeLogger("price", ch);
              }
              break;
            case "swap":
              if (add) {
                bot.addLogger(SwapLogger("swap", ch));
              } else {
                bot.removeLogger("swap", ch);
              }
              break;
            case "all":
              bot.removeLoggers(ch);
              if (add) {
                bot.addLogger(PriceLogger("price", ch));
                bot.addLogger(SwapLogger("swap", ch));
                bot.addLogger(WhaleLogger("whale", ch));
              }
              break;
          }
        }
      }
      String active = bot.loggersFor(ch).join(" ");
      await w.reply("Active loggers: $active");
      return true;
    } else {
      w.reply("Working on it!");
      return true;
    }
  }
}

class ContractsCommand extends Command {
  ContractsCommand(name, short, syntax, help)
      : super(name, short, syntax, help);

  @override
  Future<bool> exec(RoboWrapper bot) async {
    dynamic answer;
    if (bot is RoboDiscord) {
      answer = EmbedBuilder()
        ..addAuthor((author) {
          author.name = "Links to CORE token and CORE-ETH trading pair";
          //author.iconUrl = e.message.author.avatarURL();
        })
        ..addField(
            name: "CORE token on Uniswap",
            content:
                "https://uniswap.info/token/0x62359ed7505efc61ff1d56fef82158ccaffa23d7")
        ..addField(
            name: "CORE token on Etherscan",
            content:
                "https://etherscan.io/address/0x62359ed7505efc61ff1d56fef82158ccaffa23d7")
        ..addField(
            name: "CORE-ETH pair on Uniswap",
            content:
                "https://uniswap.info/pair/0x32ce7e48debdccbfe0cd037cc89526e4382cb81b")
        ..addField(
            name: "CORE-ETH pair on Etherscan",
            content:
                "https://etherscan.io/address/0x32ce7e48debdccbfe0cd037cc89526e4382cb81b")
        ..color = bot.color();
    } else {
      answer = """
Links to CORE token and CORE-ETH trading pair
<a href="https://uniswap.info/token/0x62359ed7505efc61ff1d56fef82158ccaffa23d7">CORE token on Uniswap</a>
<a href="https://etherscan.io/address/0x62359ed7505efc61ff1d56fef82158ccaffa23d7">CORE token on Etherscan</a>
<a href="https://uniswap.info/pair/0x32ce7e48debdccbfe0cd037cc89526e4382cb81b">CORE-ETH pair on Uniswap</a>
<a href="https://etherscan.io/address/0x32ce7e48debdccbfe0cd037cc89526e4382cb81b">CORE-ETH pair on Etherscan</a>
""";
    }
    await bot.reply(answer);
    return true;
  }
}

class StatsCommand extends Command {
  StatsCommand(name, short, syntax, help) : super(name, short, syntax, help);

  @override
  Future<bool> exec(RoboWrapper w) async {
    dynamic answer;
    var bot = w.bot;
    await bot.updatePriceInfo();
    if (w is RoboDiscord) {
      answer = EmbedBuilder()
        ..addField(
            name: "Pooled",
            content: "${dec0(bot.poolCORE)} CORE, ${dec0(bot.poolETH)} ETH")
        ..addField(
            name: "Liquidity",
            content: "${usd0(bot.poolETHinUSD + bot.poolCOREinUSD)}")
        ..addField(name: "Total issued LP", content: "${dec0(bot.supplyLP)}")
        ..addField(
            name: "Cumulative rewards",
            content:
                "${usd0(bot.rewardsInUSD)} (${dec2(bot.rewardsInCORE)} CORE)")
        ..addFooter((footer) {
          footer.text = "Stay CORE and keep HODLING!";
        })
        ..timestamp = DateTime.now().toUtc()
        ..color = w.color();
    } else {
      answer = """
<b>Pooled</b>
${dec0(bot.poolCORE)} CORE, ${dec0(bot.poolETH)} ETH
<b>Liquidity</b>
${usd0(bot.poolETHinUSD + bot.poolCOREinUSD)}
<b>Total issued LP</b>
${dec0(bot.supplyLP)}
<b>Cumulative rewards</b>
${usd0(bot.rewardsInUSD)} (${dec2(bot.rewardsInCORE)} CORE)

Stay CORE and keep HODLING!
""";
    }
    await w.reply(answer);
    return true;
  }
}

class MentionCommand extends Command {
  MentionCommand(name, short, syntax, help) : super(name, short, syntax, help);

  @override
  Future<bool> exec(RoboWrapper bot) async {
    if (bot is RoboDiscord && bot.isMention()) {
      const replies = [
        "Who, me? I am good! :smile:",
        "Well, thank you! :blush:",
        "You are crazy man, just crazy :rofl:",
        "Frankly, my dear, I don't give a damn! :frog:",
        "Just keep swimming :fish:",
        "My name is CORE. Robo CORE. :robot:",
        "Run you fools. Run! :scream:",
        "Even the smallest bot can change the course of the future.",
        "It's always darkest just before it goes pitch black"
      ];
      var reply = replies[Random().nextInt(replies.length)];
      await bot.reply(reply);
      return true;
    }
    return false;
  }

  @override
  String get command => " @RoboCORE";
}
