import 'package:robocore/chat/robomessage.dart';
import 'package:robocore/commands/command.dart';
import 'package:robocore/ethereum.dart';
import 'package:robocore/util.dart';

class GuardCommand extends Command {
  GuardCommand()
      : super("pair", "", "pair",
            "Show pair statistics, refreshed every minute.");

  @override
  handleMessage(RoboMessage w) async {
    var parts = w.parts;
    String? coin;
    // Only !pair
    if (parts.length == 1) {
      try {
        var s1 = ethereum.CORE2ETH.stats;
        var s2 = ethereum.CORE2CBTC.stats;
        var base = double.parse(s1[0]?['volumeUSD']);
        var vol1 = [1, 6, 24, 48]
            .map((h) => base - double.parse(s1[h]?['volumeUSD']))
            .toList();
        base = double.parse(s2[0]?['volumeUSD']);
        var vol2 = [1, 6, 24, 48]
            .map((h) => base - double.parse(s2[h]?['volumeUSD']))
            .toList();
        w
          ..addField("CORE-ETH Volume USD",
              "1h: ${usd2(vol1[0])}, 6h: ${usd2(vol1[1])}, 24h: ${usd2(vol1[2])}, 48h: ${usd2(vol1[3])}")
          ..addFooter("Stay CORE and keep HODLING!")
          ..addField("CORE-CBTC Volume USD",
              "1h: ${usd2(vol2[0])}, 6h: ${usd2(vol2[1])}, 24h: ${usd2(vol2[2])}, 48h: ${usd2(vol2[3])}")
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
