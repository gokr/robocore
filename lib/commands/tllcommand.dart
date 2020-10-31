import 'package:nyxx/nyxx.dart';
import 'package:robocore/chat/robodiscordmessage.dart';
import 'package:robocore/chat/robomessage.dart';
import 'package:robocore/commands/command.dart';
import 'package:robocore/util.dart';

class TLLCommand extends Command {
  TLLCommand()
      : super("tll", "t", "tll|t",
            "Show current TLL (Total Liquidity Locked) and TVPL (Total Value Permanently Locked).");

  @override
  handleMessage(RoboMessage bot) async {
    dynamic answer;
    await bot.bot.updatePriceInfo(null);
    if (bot is RoboDiscordMessage) {
      answer = EmbedBuilder()
        ..addAuthor((author) {
          author.name = "Pairs CORE-ETH, CORE-CBTC";
          //author.iconUrl = e.message.author.avatarURL();
        })
        ..addField(
            name: "Total Liquidity Locked (TLL)",
            content: "${usd2(bot.bot.TLLinUSD)}")
        ..addField(
            name: "Total Value Permanently Locked (TVPL)",
            content: "${usd2(bot.bot.TVPLinUSD)}")
        /*..addField(
            name: "Percent TVPL of TLL",
            content: "${dec2(100 * (bot.bot.TVPLinUSD / bot.bot.TLLinUSD))}%")*/
        ..timestamp = DateTime.now().toUtc()
        ..color = bot.color();
    } else {
      answer = """
<b>Total Liquidity Locked (TLL)</b>
${usd2(bot.bot.TLLinUSD)} (CORE-ETH, CORE-CBTC)
<b>Total Value Permanently Locked (TVPL)</b>
${usd2(bot.bot.TVPLinUSD)} (CORE-ETH, CORE-CBTC)
""";
/*<b>Percent TVPL of TLL</b>
${dec2(100 * (bot.bot.TVPLinUSD / bot.bot.TLLinUSD))}%
*/
    }
    return await bot.reply(answer);
  }
}
