import 'package:robocore/chat/robomessage.dart';
import 'package:robocore/commands/command.dart';
import 'package:robocore/ethereum.dart';
import 'package:robocore/pair.dart';
import 'package:robocore/util.dart';
import 'package:timeago/timeago.dart' as timeago;

class PairCommand extends Command {
  PairCommand()
      : super("pair", "", "pair [pairname attribute delta intervals]",
            "Show pair statistics, refreshed every minute.");

  @override
  handleMessage(RoboMessage w) async {
    var parts = w.parts;
    // Only !pair
    if (parts.length == 1) {
      try {
        const intervals = [0, 1, 6, 24, 48];
        var vol1 = ethereum.CORE2ETH.statsArray(intervals, 'volumeUSD');
        vol1 = vol1.baseline(vol1.first);
        // We had to hack this one because Uniswap sends 0
        var vol2 = ethereum.CORE2CBTC.statsArray(intervals, 'volumeToken1');
        vol2 = vol2.baseline(vol2.first);
        var priceWBTCinUSD = ethereum.WBTC2USDT.price1;
        vol2 = vol2.map((btc) => btc * priceWBTCinUSD).toList();
        var txn1 = ethereum.CORE2ETH.statsArray(intervals, 'txCount');
        txn1 = txn1.baseline(txn1.first);
        var txn2 = ethereum.CORE2CBTC.statsArray(intervals, 'txCount');
        txn2 = txn2.baseline(txn2.first);
        var sup1 = ethereum.CORE2ETH.statsArray(intervals, 'totalSupply');
        var totalSup1 = sup1.first;
        sup1 = sup1.baseline(totalSup1);
        var sup2 = ethereum.CORE2CBTC.statsArray(intervals, 'totalSupply');
        var totalSup2 = sup2.first;
        sup2 = sup2.baseline(totalSup2);
        w
          ..addField("CORE-ETH Volume USD",
              "1h: ${usd0(vol1[1])}  6h: ${usd0(vol1[2])}  24h: ${usd0(vol1[3])}  48h: ${usd0(vol1[4])}")
          ..addField("CORE-ETH number of txns",
              "1h: ${dec0(txn1[1])}  6h: ${dec0(txn1[2])}  24h: ${dec0(txn1[3])}  48h: ${dec0(txn1[4])}")
          ..addField("CORE-ETH LP supply: ${dec2(totalSup1)}",
              "1h: ${dec2(sup1[1])}  6h: ${dec2(sup1[2])}  24h: ${dec2(sup1[3])}  48h: ${dec2(sup1[4])}")
          ..addField("CORE-CBTC Volume (CBTC as WBTC in USD)",
              "1h: ${usd0(vol2[1])}  6h: ${usd0(vol2[2])}  24h: ${usd0(vol2[3])}  48h: ${usd0(vol2[4])}")
          ..addField("CORE-CBTC number of txns",
              "1h: ${dec0(txn2[1])}  6h: ${dec0(txn2[2])}  24h: ${dec0(txn2[3])}  48h: ${dec0(txn2[4])}")
          ..addField("CORE-CBTC LP supply: ${dec2(centimilli(totalSup2))} cmLP",
              "1h: ${dec2(centimilli(sup2[1]))}  6h: ${dec2(centimilli(sup2[2]))}  24h: ${dec2(centimilli(sup2[3]))}  48h: ${dec2(centimilli(sup2[4]))}")
          ..addFooter(
              "Updated ${DateTime.now().difference(ethereum.statsTimestamp as DateTime).inSeconds} seconds ago")
          ..finish();
        return await w.reply(w.answer);
      } catch (s) {
        return await w.reply("Stats for pairs not yet available");
      }
    }
    // "!pair core-eth vol 1 6" - volume, 1h deltas, last 6 deltas
    // Shows absolute delta + delta in percent from previous
    if (parts.length == 5) {
      var pairName = parts[1];
      var valid = ["core-eth", "core-cbtc"];
      if (!valid.contains(pairName)) {
        return await w
            .reply("Pair can be ${valid.join(',')} - not \"$pairName\"");
      }
      Pair? pair = ethereum.findPair(pairName);
      if (pair == null) {
        return await w.reply("Can not find pair \"$pairName\"");
      }
      var attribute = parts[2];
      var entity = pair.findEntity(attribute);
      if (entity == null) {
        return await w.reply(
            "Attribute can be ${pair.entities.join(',')} - not \"$attribute\"");
      }
      var delta;
      try {
        delta = num.parse(parts[3]);
      } catch (ex) {
        return await w.reply(
            "Delta \"${parts[3]}\" is not a number of hours, use 6 or 0.5 etc");
      }
      var range;
      try {
        range = int.parse(parts[4]);
      } catch (ex) {
        return await w.reply("Range \"${parts[4]}\" is not an integer");
      }
      try {
        var intervals = Iterable<int>.generate(range + 1)
            .map((index) => (index * delta))
            .toList()
            .reversed
            .toList();
        var stats = await pair.fetchStats(intervals);
        var d = pair.extractArray(stats, intervals, entity.name).toList();
        var derived = d.derived();
        w.addField("${pair.name.toUpperCase()}",
            "${entity.label} in $range periods of $delta hours (total, delta, delta%)");
        for (int i = 0; i < derived.length; i++) {
          w.addField("${intervals[i]}h",
              "${entity.format(derived[i][0])}     Δ${entity.format(derived[i][1])}     ${dec2(derived[i][2])}%");
        }
        w
          ..addFooter("Stay CORE and keep HODLING!")
          ..finish();
        return await w.reply(w.answer);
      } catch (s) {
        return await w.reply("Exception calculating stats: $s");
      }
    } else {
      return await w.reply("Use $syntax");
    }
  }
}
