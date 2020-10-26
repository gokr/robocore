//    uint256 public totalETHContributed;
//    uint256 public totalCOREContributed;
//    uint256 public totalWrapTokenContributed;
import 'package:robocore/chat/robomessage.dart';
import 'package:robocore/commands/command.dart';

class LGECommand extends Command {
  LGECommand()
      : super("lge", "", "lge",
            "Show various numbers from any ongoing LGE contract.");

  @override
  handleMessage(RoboMessage w) async {
    dynamic answer;
    var bot = w.bot;
    // await bot.updateLGE2Info();
    return await w.reply("There is no ongoing LGE right now");
/*
    if (w is RoboDiscordMessage) {
      answer = EmbedBuilder()
        ..addField(
            name: "Total CORE in LGE now",
            content: "${dec2(bot.lge2CORE)} CORE, (${usd2(bot.lge2COREinUSD)})")
        ..addField(
            name: "Total WBTC in LGE now",
            content: "${dec2(bot.lge2WBTC)} WBTC, (${usd2(bot.lge2WBTCinUSD)})")
        ..addField(
            name: "Total liquidity",
            content: "${usd2(bot.lge2WBTCinUSD + bot.lge2COREinUSD)}")
        ..addField(
            name: "Contributed ETH last hour",
            content: "${usd2(bot.lge2ETHContributedLastHourInUSD)}")
        ..addField(
            name: "Market bought CORE so far",
            content:
                "${dec2(bot.lge2COREBought)} CORE, (${usd2(bot.lge2COREBoughtInUSD)})")
        ..addField(
            name: "Market bought CORE last 24 hours",
            content:
                "${dec2(bot.lge2COREBoughtLast24Hours)} CORE, (${usd2(bot.lge2COREBoughtLast24HoursInUSD)})")
        ..addFooter((footer) {
          footer.text = "Keep on swimming";
          //footer.text = "LGE2 ends in ${bot.lge2TimeLeftString()}!";
        })
        ..timestamp = DateTime.now().toUtc()
        ..color = w.color();
    } else {
      answer = """
<b>Total CORE in LGE now</b>
${dec2(bot.lge2CORE)} CORE, (${usd2(bot.lge2COREinUSD)})
<b>Total WBTC in LGE now</b>
${dec2(bot.lge2WBTC)} WBTC, (${usd2(bot.lge2WBTCinUSD)})
<b>Total liquidity</b>
${usd2(bot.lge2WBTCinUSD + bot.lge2COREinUSD)}
<b>Contributed ETH last hour</b>
${usd2(bot.lge2ETHContributedLastHourInUSD)}
<b>Bought CORE so far</b>
${dec2(bot.lge2COREBought)} CORE, (${usd2(bot.lge2COREBoughtInUSD)})
<b>Bought CORE last 24 hours</b>
${dec2(bot.lge2COREBoughtLast24Hours)} CORE, (${usd2(bot.lge2COREBoughtLast24HoursInUSD)})
""";
    }
    return await w.reply(answer);
    */
  }
}
