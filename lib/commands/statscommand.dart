import 'package:nyxx/nyxx.dart';
import 'package:robocore/chat/robodiscordmessage.dart';
import 'package:robocore/chat/robomessage.dart';
import 'package:robocore/commands/command.dart';
import 'package:robocore/util.dart';

class StatsCommand extends Command {
  StatsCommand()
      : super("stats", "s", "stats|s",
            "Show some basic statistics, refreshed every minute.");

  @override
  handleMessage(RoboMessage w) async {
    dynamic answer;
    var bot = w.bot;
    await bot.updatePriceInfo(null);
    if (w is RoboDiscordMessage) {
      answer = EmbedBuilder()
        ..addField(
            name: "Pooled CORE-ETH",
            content:
                "${dec0(bot.ethereum.CORE2ETH.pool1)} CORE, ${dec0(bot.ethereum.CORE2ETH.pool2)} ETH")
        ..addField(
            name: "Liquidity CORE-ETH",
            content:
                "${usd0(bot.ethereum.CORE2ETH.liquidity * bot.priceETHinUSD)}")
        ..addField(
            name: "Total issued CORE-ETH LP",
            content: "${dec0(bot.ethereum.CORE2ETH.supplyLP)}")
        ..addField(
            name: "Pooled CORE-CBTC",
            content:
                "${dec0(bot.ethereum.CORE2CBTC.pool1)} CORE, ${dec0(bot.ethereum.CORE2CBTC.pool2)} CBTC")
        ..addField(
            name: "Liquidity CORE-CBTC",
            content:
                "${usd0(bot.ethereum.CORE2CBTC.liquidity * bot.priceWBTCinUSD)}")
        ..addField(
            name: "Total issued CORE-CBTC cmLP",
            content: "${dec0(centimilli(bot.ethereum.CORE2CBTC.supplyLP))}")
        ..addFooter((footer) {
          footer.text = "Stay CORE and keep HODLING!";
        })
        ..timestamp = DateTime.now().toUtc()
        ..color = w.color();
    } else {
      answer = """
<b>Pooled CORE-ETH</b>
${dec0(bot.ethereum.CORE2ETH.pool1)} CORE, ${dec0(bot.ethereum.CORE2ETH.pool2)} ETH
<b>Liquidity CORE-ETH</b>
${usd0(bot.ethereum.CORE2ETH.liquidity * bot.priceETHinUSD)}
<b>Total issued CORE-ETH LP</b>
${dec0(bot.ethereum.CORE2ETH.supplyLP)}
<b>Pooled CORE-CBTC</b>
${dec0(bot.ethereum.CORE2CBTC.pool1)} CORE, ${dec0(bot.ethereum.CORE2CBTC.pool2)} CBTC
<b>Liquidity CORE-CBTC</b>
${usd0(bot.ethereum.CORE2CBTC.liquidity * bot.priceWBTCinUSD)}
<b>Total issued CORE-CBTC cmLP</b>
${dec0(centimilli(bot.ethereum.CORE2CBTC.supplyLP))}

Stay CORE and keep HODLING!
""";
    }
    return await w.reply(answer);
  }
}
