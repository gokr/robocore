import 'package:nyxx/nyxx.dart';
import 'package:robocore/chat/robodiscordmessage.dart';
import 'package:robocore/chat/robomessage.dart';
import 'package:robocore/commands/command.dart';

class PriceCommand extends Command {
  PriceCommand()
      : super("price", "p", "price|p [[\"amount\"] eth|core|lp]",
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
          ..addField(name: "Price CORE", content: bot.bot.priceStringCORE())
          ..addField(name: "Price ETH", content: bot.bot.priceStringETH())
          ..addField(name: "Price WBTC", content: bot.bot.priceStringWBTC())
          ..addField(
              name: "Price CORE-ETH LP", content: bot.bot.priceStringLP1())
          ..addField(
              name: "Price CORE-CBTC cmLP", content: bot.bot.priceStringLP2())
          ..timestamp = DateTime.now().toUtc()
          ..color = bot.color();
      } else {
        answer = """
<b>Price CORE:</b> ${bot.bot.priceStringCORE()}
<b>Price ETH:</b> ${bot.bot.priceStringETH()}
<b>Price WBTC:</b> ${bot.bot.priceStringWBTC()}
<b>Price CORE-ETH LP:</b> ${bot.bot.priceStringLP1()}
<b>Price CORE-CBTC LP:</b> ${bot.bot.priceStringLP2()}
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
    if (!["core", "eth", "btc", "lp", "lp2"].contains(coin)) {
      return await bot
          .reply("Coin can be core, eth, btc, lp or lp2, not \"$coin\"");
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
      case "lp":
        await bot.reply(bot.bot.priceStringLP1(amount));
        break;
      case "lp2":
        await bot.reply(bot.bot.priceStringLP2(amount));
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
