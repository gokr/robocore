import 'package:robocore/chat/robomessage.dart';
import 'package:robocore/commands/command.dart';
import 'package:robocore/util.dart';

class LGECommand extends Command {
  LGECommand()
      : super("lge", "", "lge",
            "Show various numbers from any ongoing LGE contract.");

  @override
  handleMessage(RoboMessage w) async {
    var bot = w.bot;
    await bot.updateLGE3Info();
    return await w.reply("There is no ongoing LGE right now, lGE3 is finished");
    /*w
      ..addField("Total CORE in LGE now",
          "${dec2(bot.lge3CORE)} CORE, (${usd2(bot.lge3COREinUSD)})")
      ..addField("Total DAI in LGE now",
          "${dec2(bot.lge3DAI)} DAI, (${usd2(bot.lge3DAIinUSD)})")
      ..addField("Total WETH in LGE now",
          "${dec2(bot.lge3WETH)} WETH, (${usd2(bot.lge3WETHinUSD)})")
      ..addField("Total liquidity",
          "${usd2(bot.lge3DAIinUSD + bot.lge3COREinUSD + bot.lge3WETHinUSD)}")
      ..addField("Contributed value in USD last hour",
          "${usd2(bot.lge3COREContributedLastHourInUSD)}")
      ..addField("Market bought CORE so far",
          "${dec2(bot.lge3COREBought)} CORE, (${usd2(bot.lge3COREBoughtInUSD)})")
      ..addField("Market bought CORE last 24 hours",
          "${dec2(bot.lge3COREBoughtLast24Hours)} CORE, (${usd2(bot.lge3COREBoughtLast24HoursInUSD)})")
      //..addFooter("LGE3 ends in ${bot.lge3TimeLeftString()}!")
      ..finish();
    return await w.reply(w.answer);*/
  }
}
