import 'package:nyxx/nyxx.dart';
import 'package:robocore/chat/robodiscordmessage.dart';
import 'package:robocore/chat/robomessage.dart';
import 'package:robocore/commands/command.dart';

class PriceCommand extends Command {
  PriceCommand()
      : super("price", "p", "price|p [[\"amount\"] eth|core|btc|lp1|lp2]",
            "Show prices, straight from Ethereum. \"!p core\" shows only price for CORE. You can also use an amount like \"!p 10 core\".");

  @override
  handleMessage(RoboMessage bot) async {
    await bot.bot.updatePriceInfo(null);
    var parts = bot.parts;
    String? coin, amountString;
    num amount = 1;
    // Only !p or !price
    if (parts.length == 1) {
      dynamic answer;
      if (bot is RoboDiscordMessage) {
        answer = EmbedBuilder()
          ..addAuthor((author) {
            author.name = "Prices fresh from contracts";
            //author.iconUrl = e.message.author.avatarURL();
          })
          ..addField(name: "CORE", content: bot.bot.priceStringCORE())
          ..addField(name: "ETH", content: bot.bot.priceStringETH())
          ..addField(name: "WBTC", content: bot.bot.priceStringWBTC())
          ..addField(
              name: "CORE-ETH LP value", content: bot.bot.valueStringLP1())
          ..addField(
              name: "CORE-ETH LP balancer", content: bot.bot.priceStringLP1())
          ..addField(
              name: "CORE-CBTC cmLP value", content: bot.bot.valueStringLP2())
          ..addField(
              name: "CORE-CBTC cmLP balancer",
              content: bot.bot.priceStringLP2())
          ..timestamp = DateTime.now().toUtc()
          ..color = bot.color();
      } else {
        answer = """
<b>CORE:</b> ${bot.bot.priceStringCORE()}
<b>ETH:</b> ${bot.bot.priceStringETH()}
<b>WBTC:</b> ${bot.bot.priceStringWBTC()}
<b>CORE-ETH LP value:</b> ${bot.bot.valueStringLP1()}
<b>CORE-ETH LP balancer:</b> ${bot.bot.priceStringLP1()}
<b>CORE-CBTC LP value:</b> ${bot.bot.valueStringLP2()}
<b>CORE-CBTC LP balancer:</b> ${bot.bot.priceStringLP2()}
""";
      }
      return await bot.reply(answer);
    }
    // Also coin given
    if (parts.length == 2) {
      coin = parts[1].toLowerCase();
    } else {
      coin = parts[2].toLowerCase();
      amountString = parts[1];
    }
    var validCoins = (bot.isDirectChat)
        ? [
            "core",
            "eth",
            "btc",
            "lp",
            "lp1",
            "lp2",
            "cmlp",
            "flp1",
            "flp2",
            "fcore"
          ]
        : [
            "core",
            "eth",
            "btc",
            "lp",
            "lp1",
            "lp2",
            "cmlp",
          ];
    // Check valid coins
    if (!validCoins.contains(coin)) {
      return await bot.reply((bot.isDirectChat)
          ? "Coin can be core, eth, btc, lp (or lp1), lp2 (or cmlp), fcore, flp1 or flp2 - not \"$coin\""
          : "Coin can be core, eth, btc, lp (or lp1) or lp2 (or cmlp) - not \"$coin\"");
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
      case "btc":
        await bot.reply(bot.bot.priceStringWBTC(amount));
        break;
      case "lp1":
      case "lp":
        await bot.reply(bot.bot.valueStringLP1(amount) +
            ' balancer: ' +
            bot.bot.priceStringLP1(amount));
        break;
      case "lp2":
      case "cmlp":
        await bot.reply(bot.bot.valueStringLP2(amount) +
            ' balancer: ' +
            bot.bot.priceStringLP2(amount));
        break;
      case "fcore":
        await bot.reply(bot.bot.floorStringCORE(amount));
        break;
      case "flp1":
        await bot.reply(bot.bot.floorStringLP1(amount));
        break;
      case "flp2":
        await bot.reply(bot.bot.floorStringLP2(amount));
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
