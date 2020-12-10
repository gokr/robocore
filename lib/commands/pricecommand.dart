import 'package:robocore/chat/robomessage.dart';
import 'package:robocore/commands/command.dart';

class PriceCommand extends Command {
  PriceCommand()
      : super(
            "price",
            "p",
            "price|p [[\"amount\"] eth|fanny|dai|core|btc|lp1|lp2|lp3]",
            "Show prices, straight from Ethereum. \"!p core\" shows only price for CORE. You can also use an amount like \"!p 10 core\".");

  @override
  handleMessage(RoboMessage w) async {
    await w.bot.updatePriceInfo(null);
    var parts = w.parts;
    String? coin, amountString;
    num amount = 1;
    // Only !p or !price
    if (parts.length == 1) {
      w
        ..addField("Prices", w.bot.prices())
        ..addField("CORE-ETH LP value", w.bot.valueStringLP1())
        ..addField("CORE-ETH LP balancer", w.bot.priceStringLP1())
        ..addField("CORE-CBTC cmLP value", w.bot.valueStringLP2())
        ..addField("CORE-CBTC cmLP balancer", w.bot.priceStringLP2())
        ..addField("coreDAI-wCORE LP value", w.bot.valueStringLP3())
        ..addField("coreDAI-wCORE LP balancer", w.bot.priceStringLP3())
        ..finish();
      return await w.reply(w.answer);
    }
    // Also coin given
    if (parts.length == 2) {
      coin = parts[1];
    } else {
      coin = parts[2];
      amountString = parts[1];
    }
    var validCoins = (w.isDirectChat)
        ? [
            "core",
            "fanny",
            "dai",
            "eth",
            "btc",
            "lp",
            "lp1",
            "lp2",
            "lp3",
            "cmlp",
            "flp1",
            "flp2",
            "flp3",
            "fcore"
          ]
        : [
            "core",
            "fanny",
            "dai",
            "eth",
            "btc",
            "lp",
            "lp1",
            "lp2",
            "lp3",
            "cmlp",
          ];
    // Check valid coins
    if (!validCoins.contains(coin)) {
      return await w.reply((w.isDirectChat)
          ? "Coin can be core, fanny, dai, eth, btc, lp (or lp1), lp2 (or cmlp), lp3, fcore, flp1, flp2, flp3 - not \"$coin\""
          : "Coin can be core, fanny, dai, eth, btc, lp (or lp1) or lp2 (or cmlp), lp3 - not \"$coin\"");
    }
    // Parse amount as num
    if (amountString != null) {
      try {
        amount = num.parse(amountString);
      } catch (ex) {
        return await w.reply(
            "Amount \"${parts[2]}\" is not a number, use for example \"!p 10 core\"");
      }
    }
    // Time to answer
    switch (coin) {
      case "core":
        await w.reply(w.bot.priceStringCORE(amount));
        break;
      case "fanny":
        await w.reply(w.bot.priceStringFANNY(amount));
        break;
      case "dai":
        await w.reply(w.bot.priceStringDAI(amount));
        break;
      case "eth":
        await w.reply(w.bot.priceStringETH(amount));
        break;
      case "btc":
        await w.reply(w.bot.priceStringWBTC(amount));
        break;
      case "lp1":
      case "lp":
        await w.reply(w.bot.valueStringLP1(amount) +
            ' balancer: ' +
            w.bot.priceStringLP1(amount));
        break;
      case "lp2":
      case "cmlp":
        await w.reply(w.bot.valueStringLP2(amount) +
            ' balancer: ' +
            w.bot.priceStringLP2(amount));
        break;
      case "lp3":
        //await w.reply(w.bot.valueStringLP3(amount));
        await w.reply(w.bot.valueStringLP3(amount) +
            ' balancer: ' +
            w.bot.priceStringLP3(amount));
        break;
      case "fcore":
        await w.reply(w.bot.floorStringCORE(amount));
        break;
      case "flp1":
        await w.reply(w.bot.floorStringLP1(amount));
        break;
      case "flp2":
        await w.reply(w.bot.floorStringLP2(amount));
        break;
      case "flp3":
        await w.reply(w.bot.floorStringLP3(amount));
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
