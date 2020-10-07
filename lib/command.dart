import 'dart:math';

import 'package:nyxx/nyxx.dart';
import 'package:robocore/core.dart';
import 'package:robocore/robocore.dart';

const prefix = "!";

abstract class Command {
  String name, short, help;
  List<String> blacklist = [];
  List<String> whitelist = [];

  Command(this.name, this.short, this.help, this.whitelist, this.blacklist);

  /// Perform the command, returns true if we matched
  Future<bool> exec(MessageReceivedEvent e, Robocore robot);

  /// Default implementation of matching a message
  bool valid(MessageReceivedEvent e) {
    return e.message.content.startsWith(prefix + name) ||
        e.message.content.startsWith(prefix + short);
  }

  bool availableIn(String channel) {
    return true;
  }

  String get command => "$prefix$name";
}

class HelpCommand extends Command {
  HelpCommand(name, short, help, List<String> whitelist, List<String> blacklist)
      : super(name, short, help, whitelist, blacklist);

  @override
  Future<bool> exec(MessageReceivedEvent e, Robocore robot) async {
    if (valid(e)) {
      await e.message.channel.send(content: robot.buildHelp(e.message.channel));
      return true;
    }
    return false;
  }
}

class PriceCommand extends Command {
  PriceCommand(
      name, short, help, List<String> whitelist, List<String> blacklist)
      : super(name, short, help, whitelist, blacklist);

  @override
  Future<bool> exec(MessageReceivedEvent e, Robocore bot) async {
    if (valid(e)) {
      await bot.updatePriceInfo();
      final embed = EmbedBuilder()
        ..addAuthor((author) {
          author.name = "Prices fresh directly from contracts";
          //author.iconUrl = e.message.author.avatarURL();
        })
        ..addField(
            name: "Price CORE",
            content:
                "1 CORE = ${usd2(bot.priceCOREinUSD)} (${dec4(bot.priceCOREinETH)} ETH)")
        ..addField(
            name: "Price ETH",
            content:
                "1 ETH = ${usd2(bot.priceETHinUSD)} (${dec6(bot.priceETHinCORE)} CORE)")
        ..addField(
            name: "Price LP",
            content:
                "1 LP = ${usd2(bot.priceLPinUSD)} (${dec4(bot.priceLPinETH)} ETH)")
        ..addField(
            name: "Floor CORE",
            content:
                "1 CORE = ${usd2(bot.floorCOREinUSD)} (${dec4(bot.floorCOREinETH)} ETH)")
        ..addField(
            name: "Floor LP",
            content:
                "1 LP = ${usd2(bot.floorLPinUSD)} (${dec4(bot.floorLPinETH)} ETH)")
        ..color = (e.message.author is CacheMember)
            ? (e.message.author as CacheMember).color
            : DiscordColor.black;
      await e.message.channel.send(embed: embed);
      return true;
    }
    return false;
  }
}

class FAQCommand extends Command {
  FAQCommand(name, short, help, List<String> whitelist, List<String> blacklist)
      : super(name, short, help, whitelist, blacklist);

  @override
  Future<bool> exec(MessageReceivedEvent e, Robocore bot) async {
    if (valid(e)) {
      final embed = EmbedBuilder()
        ..addField(name: "FAQ", content: "https://help.cvault.finance/faqs/faq")
        ..addAuthor((author) {
          author.name = e.message.author.username;
          author.iconUrl = e.message.author.avatarURL();
        })
        ..addFooter((footer) {
          footer.text = "Keep HODLING";
        })
        ..color = (e.message.author is CacheMember)
            ? (e.message.author as CacheMember).color
            : DiscordColor.black;
      await e.message.channel.send(embed: embed);
      return true;
    }
    return false;
  }
}

class ContractsCommand extends Command {
  ContractsCommand(
      name, short, help, List<String> whitelist, List<String> blacklist)
      : super(name, short, help, whitelist, blacklist);

  @override
  Future<bool> exec(MessageReceivedEvent e, Robocore bot) async {
    if (valid(e)) {
      final embed = EmbedBuilder()
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
        ..color = (e.message.author is CacheMember)
            ? (e.message.author as CacheMember).color
            : DiscordColor.black;
      await e.message.channel.send(embed: embed);
      return true;
    }
    return false;
  }
}

class StatsCommand extends Command {
  StatsCommand(
      name, short, help, List<String> whitelist, List<String> blacklist)
      : super(name, short, help, whitelist, blacklist);

  @override
  Future<bool> exec(MessageReceivedEvent e, Robocore bot) async {
    await bot.updatePriceInfo();
    if (valid(e)) {
      final embed = EmbedBuilder()
        ..addField(
            name: "Pooled",
            content: "${dec0(bot.poolCORE)} CORE, ${dec0(bot.poolETH)} ETH")
        ..addField(
            name: "Liquidity",
            content: "${usd0(bot.poolETHinUSD + bot.poolCOREinUSD)}")
        ..addField(
            name: "Cumulative rewards",
            content:
                "${usd0(bot.rewardsInUSD)}, (${dec2(bot.rewardsInCORE)} CORE)")
        ..addFooter((footer) {
          footer.text = "Stay CORE and keep HODLING!";
        })
        ..color = (e.message.author is CacheMember)
            ? (e.message.author as CacheMember).color
            : DiscordColor.black;
      await e.message.channel.send(embed: embed);
      return true;
    }
    return false;
  }
}

class MentionCommand extends Command {
  MentionCommand(
      name, short, help, List<String> whitelist, List<String> blacklist)
      : super(name, short, help, whitelist, blacklist);

  @override
  Future<bool> exec(MessageReceivedEvent e, Robocore bot) async {
    if (e.message.mentions.contains(bot.self)) {
      const replies = [
        "Who, me? I am good! :smile:",
        "Well, thank you! :blush:",
        "You are crazy man, just crazy :rofl:",
        "Who, me? I am good! :smile:",
        "Frankly, my dear, I don't give a damn! :frog:",
        "Just keep swimming :fish:",
        "My name is CORE. Robo CORE. :robot:",
        "Run you fools. Run! :scream:"
      ];
      var reply = replies[Random().nextInt(replies.length)];
      await e.message.channel.send(content: reply);
      return true;
    }
    return false;
  }

  @override
  String get command => " @RoboCORE";
}
