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

String randomOf(List<String> list) {
  return list[Random().nextInt(list.length)];
}

abstract class Command {
  String name, short, syntax, help;
  List<int> blacklist = [];
  List<int> whitelist = [];
  List<int> users = [];

  /// Is this command fine for everyone, if executed in direct chat?
  bool validForAllInDM = true;

  Command(this.name, this.short, this.syntax, this.help);

  /// Handle the message
  handleMessage(RoboMessage bot);

  /// Handle the command, returns a String if handled, otherwise null
  Future<String?> inlineTelegram(String cmd, Robocore robot) async {
    return null;
  }

  /// Either whitelisted or blacklisted (can't be both)
  bool validForChannelId(int id) {
    if (whitelist.isNotEmpty) {
      return whitelist.contains(id);
    } else {
      return !blacklist.contains(id);
    }
  }

  /// If a command is valid for given user id
  bool validForUserId(int id) {
    return users.isEmpty || users.contains(id);
  }

  /// Is this Command valid to execute for this message? Double dispatch
  bool isValid(RoboMessage bot) {
    return bot.validCommand(this);
  }

  String get command => "$discordPrefix$name";
  String get shortCommand => "$discordPrefix$short";
}

class HelpCommand extends Command {
  HelpCommand()
      : super("help", "h", "help|h", "Show all commands of RoboCORE.");

  @override
  handleMessage(RoboMessage bot) async {
    return await bot.reply(bot.buildHelp());
  }
}

class AdminCommand extends Command {
  AdminCommand()
      : super("admin", "a", "admin|a", "Special RoboCORE admin stuff.");

  @override
  handleMessage(RoboMessage bot) async {
    var parts = bot.parts;
    // channel = Show this channel
    if (parts.length == 1) {
      return await bot.reply("Need sub command");
    }
    if (parts[1] == "channelid") {
      return await bot.reply("Channel id: ${bot.channelId}");
    }
  }
}

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
  PriceCommand()
      : super("price", "p", "price|p [[\"amount\"] eth|core|lp]",
            "Show prices, straight from Ethereum. \"!p core\" shows only price for CORE. You can also use an amount like \"!p 10 core\".");

  @override
  handleMessage(RoboMessage bot) async {
    await bot.bot.updatePriceInfo();
    var parts = bot.parts;
    String? coin, amountString;
    num amount = 1;
    // Only !p or !price
    if (parts.length == 1) {
      dynamic answer;
      if (bot is RoboDiscordMessage) {
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
      return await bot.reply(answer);
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
      return await bot.reply("Coin can be core, eth or lp, not \"$coin\"");
    }
    // Parse amount as num
    if (amountString != null) {
      try {
        amount = num.parse(amountString);
      } catch (ex) {
        return await bot.reply(
            "Amount \"${parts[2]}\" is not a number, use for example \"!p 10 core\"");
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
    return;
  }

  /// Handle the command, returns true if handled
  /*Future<String?> inlineTelegram(String cmd, Robocore robot) async {
    if (_validTelegramCommand(cmd)) {
      return robot.priceStringCORE(1);
    }
  }*/
}

class FloorCommand extends Command {
  FloorCommand() : super("floor", "f", "floor|f", "Show current floor prices.");

  @override
  handleMessage(RoboMessage bot) async {
    dynamic answer;
    await bot.bot.updatePriceInfo();
    if (bot is RoboDiscordMessage) {
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
    return await bot.reply(answer);
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
  FAQCommand() : super("faq", "", "faq", "Show links to FAQ etc.");

  @override
  handleMessage(RoboMessage bot) async {
    dynamic answer;
    if (bot is RoboDiscordMessage) {
      answer = EmbedBuilder()
        ..addAuthor((author) {
          author.name = "Various links to good info";
        })
        ..addField(name: "Help", content: "https://help.cvault.finance")
        ..addField(
            name: "Links",
            content:
                "[Twitter](https://twitter.com/CORE_Vault) [Medium](https://medium.com/core-vault) [Telegram](https://t.me/COREVault) [Github](https://github.com/cVault-finance)")
        ..addField(
            name: "Articles",
            content:
                "[Vision](https://medium.com/@0xdec4f/the-idea-project-and-vision-of-core-vault-52f5eddfbfb)")
        ..addFooter((footer) {
          footer.text = "Keep HODLING";
        })
        ..color = bot.color();
    } else {
      answer = """
*Help*
[Help](https://help.cvault.finance)
*Links*
[Twitter](https://twitter.com/CORE_Vault) [Medium](https://medium.com/core-vault) [Telegram](https://t.me/COREVault) [Github](https://github.com/cVault-finance)
*Articles*
[Vision](https://medium.com/@0xdec4f/the-idea-project-and-vision-of-core-vault-52f5eddfbfb)
""";
    }
    return bot.reply(answer, markdown: true);
  }
}

class StartCommand extends Command {
  StartCommand()
      : super("start", "", "start",
            "Just say hi and get things going! Standard procedure in Telegram, not used in Discord really.");

  @override
  handleMessage(RoboMessage bot) async {
    return bot.reply("Well, hi there ${bot.username}! What can I do for you?");
  }
}

class LogCommand extends Command {
  LogCommand()
      : super("log", "l", "log|l [add|remove] [all|price|whale|swap]",
            "Control logging of events in current channel, only log will show active loggers. Only works in private conversations with RoboCORE, or in select channels on Discord.");

  @override
  handleMessage(RoboMessage w) async {
    if (w is RoboDiscordMessage) {
      var bot = w.bot;
      var ch = w.e.message.channel;
      var parts = w.parts;
      var loggers = w.bot.loggers.where((logger) => logger.channel == ch);
      // log = shows loggers
      // log remove all = removes all
      // log add|remove xxx = adds or removes logger
      if (parts.length == 1) {
        String active = loggers.join(" ");
        return await w.reply("Active loggers: $active");
      }
      if (parts.length == 2) {
        return await w.reply(
            "Use add|remove [whale [limit] | swap | price [delta] | all]");
      }
      if (parts.length >= 3) {
        if (!["add", "remove"].contains(parts[1])) {
          return await w.reply("Use add|remove [whale|swap|price|all]");
        }
        bool add = parts[1] == "add";
        var names = parts.sublist(2);
        num? arg;
        for (int i = 0; i < names.length; i++) {
          var name = names[i];
          // If arg
          if (arg == null) {
            // One lookahead
            if (i < names.length + 1) {
              arg = num.tryParse(names[i + 1]);
            } else {
              arg = null;
            }
            switch (name) {
              case "whale":
                if (add) {
                  var logger = WhaleLogger("whale", ch);
                  if (arg != null) logger.limit = arg;
                  bot.addLogger(logger);
                } else {
                  bot.removeLogger("whale", ch);
                }
                break;
              case "price":
                if (add) {
                  var logger = PriceLogger("whale", ch);
                  if (arg != null) logger.delta = arg;
                  bot.addLogger(logger);
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
          } else {
            arg = null;
          }
        }
      }
      String active = bot.loggersFor(ch).join(" ");
      return await w.reply("Active loggers: $active");
    } else {
      return w.reply("Sorry, not yet working on Telegram!");
    }
  }
}

class ContractsCommand extends Command {
  ContractsCommand()
      : super("contracts", "c", "contracts|c",
            "Show links to relevant contracts.");

  @override
  handleMessage(RoboMessage bot) async {
    dynamic answer;
    if (bot is RoboDiscordMessage) {
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
    return await bot.reply(answer);
  }
}

class StatsCommand extends Command {
  StatsCommand()
      : super("stats", "s", "stats|s",
            "Show some basic statistics, refreshed every minute.");

  @override
  handleMessage(RoboMessage w) async {
    dynamic answer;
    var bot = w.bot;
    await bot.updatePriceInfo();
    if (w is RoboDiscordMessage) {
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
    return await w.reply(answer);
  }
}

class MentionCommand extends Command {
  MentionCommand()
      : super("@RoboCORE", "", "@RoboCORE", "I will ... say something!");

  // I am valid if the message mentions me
  bool isValid(RoboMessage bot) {
    return bot.isMention();
  }

  static const replies = [
    "Who, me? I am good! 😄",
    "Well, thank you! 😊",
    "You are crazy man, just crazy 🤣",
    "Frankly, my dear, I don't give a damn! 🐸",
    "Just keep swimming 🐟",
    "My name is CORE. Robo CORE. 🤖",
    "Run you fools. Run! 😱",
    "Even the smallest bot can change the course of the future.",
    "It's always darkest just before it goes pitch black"
  ];
  static const wittys = {
    "pump": ["Yeah! ⛽️ it up!"],
    "moon": ["Why not Mars!?"],
    "stupid": ["Who are you calling stupid?"],
    "love": ["I love you too! ❤️"],
    "lambo": ["Anything over my old Golf", "A  DeTomaso Pantera is way cooler"]
  };

  @override
  handleMessage(RoboMessage bot) async {
    // Fallback
    var reply = randomOf(replies);
    // Try be a tad smarter
    wittys.forEach((k, v) {
      if (bot.textLowerCase.contains(k)) {
        reply = randomOf(v);
      }
    });
    await bot.reply(reply);
  }

  @override
  String get command => " @RoboCORE";
}
