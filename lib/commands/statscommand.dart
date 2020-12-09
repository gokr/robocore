import 'package:robocore/chat/robomessage.dart';
import 'package:robocore/commands/command.dart';
import 'package:robocore/ethereum.dart';
import 'package:robocore/util.dart';

class StatsCommand extends Command {
  StatsCommand()
      : super("stats", "s", "stats|s",
            "Show some basic statistics, refreshed every minute.");

  @override
  handleMessage(RoboMessage w) async {
    var bot = w.bot;
    await bot.updatePriceInfo(null);
    w
      ..addField("CORE-ETH pair",
          """${dec0(ethereum.CORE2ETH.pool1)} CORE, ${dec0(ethereum.CORE2ETH.pool2)} ETH
${usd0(ethereum.CORE2ETH.liquidity * bot.priceETHinUSD)} (${dec0(ethereum.CORE2ETH.supplyLP)} LP)""")
      ..addField("CORE-CBTC pair",
          """${dec0(ethereum.CORE2CBTC.pool1)} CORE, ${dec0(ethereum.CORE2CBTC.pool2)} CBTC
${usd0(ethereum.CORE2CBTC.liquidity * bot.priceWBTCinUSD)} (${dec0(centimilli(ethereum.CORE2CBTC.supplyLP))} cmLP)""")
      ..addField("coreDAI-wCORE pair",
          """${dec0(ethereum.COREDAI2WCORE.pool1)} coreDAI, ${dec0(ethereum.COREDAI2WCORE.pool2)} wCORE
${usd0(ethereum.COREDAI2WCORE.liquidity * bot.priceCOREinUSD)} (${dec0(ethereum.COREDAI2WCORE.supplyLP)} LP3)""")
      ..addField("CORE-FANNY pair",
          """${dec0(ethereum.CORE2FANNY.pool1)} CORE, ${dec0(ethereum.CORE2FANNY.pool2)} FANNY
${usd0(ethereum.CORE2FANNY.liquidity * bot.priceFANNYinUSD)}""")
      ..finish();

    return await w.reply(w.answer);
  }
}
