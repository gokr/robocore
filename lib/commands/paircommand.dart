import 'package:robocore/chat/robomessage.dart';
import 'package:robocore/commands/command.dart';
import 'package:robocore/ethereum.dart';
import 'package:robocore/util.dart';

class PairCommand extends Command {
  PairCommand()
      : super("pair", "", "pair",
            "Show pair statistics, refreshed every minute.");

  @override
  handleMessage(RoboMessage w) async {
    var parts = w.parts;
    String? coin;
    // Only !pair
    if (parts.length == 1) {
      try {
        var vol1 = ethereum.CORE2ETH.statsArray([1, 6, 24, 48], 'volumeUSD');
        // We had to hack this one because Uniswap sends 0
        var vol2 =
            ethereum.CORE2CBTC.statsArray([1, 6, 24, 48], 'volumeToken1');
        var priceWBTCinUSD = ethereum.WBTC2USDT.price1;
        vol2 = vol2.map((btc) => btc * priceWBTCinUSD).toList();
        var txn1 = ethereum.CORE2ETH.statsArray([1, 6, 24, 48], 'txCount');
        var txn2 = ethereum.CORE2CBTC.statsArray([1, 6, 24, 48], 'txCount');
        var sup1 = ethereum.CORE2ETH.statsArray([1, 6, 24, 48], 'totalSupply');
        var sup2 = ethereum.CORE2CBTC.statsArray([1, 6, 24, 48], 'totalSupply');
        w
          ..addField("CORE-ETH Volume USD",
              "1h: ${usd0(vol1[1])}  6h: ${usd0(vol1[2])}  24h: ${usd0(vol1[3])}  48h: ${usd0(vol1[4])}")
          ..addField("CORE-ETH number of txns",
              "1h: ${dec0(txn1[1])}  6h: ${dec0(txn1[2])}  24h: ${dec0(txn1[3])}  48h: ${dec0(txn1[4])}")
          ..addField("CORE-ETH LP supply: ${dec2(sup1[0])}",
              "1h: ${dec2(sup1[1])}  6h: ${dec2(sup1[2])}  24h: ${dec2(sup1[3])}  48h: ${dec2(sup1[4])}")
          ..addField("CORE-CBTC Volume (CBTC as WBTC in USD)",
              "1h: ${usd0(vol2[1])}  6h: ${usd0(vol2[2])}  24h: ${usd0(vol2[3])}  48h: ${usd0(vol2[4])}")
          ..addField("CORE-CBTC number of txns",
              "1h: ${dec0(txn2[1])}  6h: ${dec0(txn2[2])}  24h: ${dec0(txn2[3])}  48h: ${dec0(txn2[4])}")
          ..addField("CORE-CBTC LP supply: ${dec2(centimilli(sup2[0]))} cmLP",
              "1h: ${dec2(centimilli(sup2[1]))}  6h: ${dec2(centimilli(sup2[2]))}  24h: ${dec2(centimilli(sup2[3]))}  48h: ${dec2(centimilli(sup2[4]))}")
          ..addFooter("Stay CORE and keep HODLING!")
          ..finish();
        return await w.reply(w.answer);
      } catch (s) {
        return await w.reply("Stats for pairs not yet available");
      }
    }
    // "!pair vol 1 6" - 1h, last 6
    // Shows absolute delta + delta in percent from previous
    if (parts.length > 2) {}
  }
}
