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
          author.name = "Floor prices calculated from contracts";
          //author.iconUrl = e.message.author.avatarURL();
        })
        ..addField(
            name: "Floor CORE (will soon be updated)",
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
