import 'package:nyxx/nyxx.dart';
import 'package:robocore/chat/robodiscordmessage.dart';
import 'package:robocore/chat/robomessage.dart';
import 'package:robocore/commands/command.dart';
import 'package:robocore/util.dart';

class FloorCommand extends Command {
  FloorCommand() : super("floor", "f", "floor|f", "Show current floor prices.");

  @override
  handleMessage(RoboMessage bot) async {
    dynamic answer;
    await bot.bot.updatePriceInfo(null);
    if (bot is RoboDiscordMessage) {
      answer = EmbedBuilder()
        ..addAuthor((author) {
          author.name = "Floor prices from contracts";
          //author.iconUrl = e.message.author.avatarURL();
        })
        ..addField(
            name: "Floor CORE",
            content:
                "1 CORE = ${usd2(bot.bot.floorCOREinUSD)} (${dec4(bot.bot.floorCOREinETH)} ETH)")
        ..addField(
            name: "Floor CORE-ETH LP",
            content:
                "1 LP = ${usd2(bot.bot.floorLPinUSD)} (${dec4(bot.bot.floorLPinETH)} ETH)")
        ..addField(
            name: "Floor CORE-CBTC LP",
            content:
                "1 cmLP = ${usd2(toCentimilli(bot.bot.floorLP2inUSD))} (${dec4(toCentimilli(bot.bot.floorLP2inWBTC))} CBTC)")
        ..timestamp = DateTime.now().toUtc()
        ..color = bot.color();
    } else {
      answer = """
<b>Floor CORE</b>
1 CORE = ${usd2(bot.bot.floorCOREinUSD)} (${dec4(bot.bot.floorCOREinETH)} ETH)
<b>Floor CORE-ETH LP</b>
1 LP = ${usd2(bot.bot.floorLPinUSD)} (${dec4(bot.bot.floorLPinETH)} ETH)
<b>Floor CORE-CBTC LP</b>
1 cmLP = ${usd2(toCentimilli(bot.bot.floorLP2inUSD))} (${dec4(toCentimilli(bot.bot.floorLP2inWBTC))} CBTC)
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
