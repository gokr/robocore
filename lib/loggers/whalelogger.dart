import 'dart:math';

import 'package:nyxx/nyxx.dart';
import 'package:robocore/chat/robochannel.dart';
import 'package:robocore/chat/robodiscord.dart';
import 'package:robocore/loggers/eventlogger.dart';
import 'package:robocore/pair.dart';
import 'package:robocore/robocore.dart';
import 'package:robocore/model/swap.dart';
import 'package:robocore/util.dart';

class WhaleLogger extends EventLogger {
  // Amount in token1
  num limit = 10;

  WhaleLogger(String name, Pair pair, RoboChannel channel)
      : super(name, pair, channel);

  String makeHearts(num eth, int limit) {
    return makeRepeatedString(eth.round(), "💚", limit);
  }

  String makeSorrys(num eth, int limit) {
    var char =
        ["🚫", "💔", "👅", "🐷", "🌶", "⛔️", "💢", "⁉️", "🔻"].pickRandom();
    return makeRepeatedString(eth.round(), char, limit);
  }

  // For Discord
  String makeHappies(num core, int limit) {
    var char = ["🦕", "🐉", "💚", "🍀", "🍏", "✅"].pickRandom();
    return makeRepeatedString(core.round(), char, limit);
  }

  String toString() => "$name($pair, >$limit)";
}

class WhaleSellLogger extends WhaleLogger {
  WhaleSellLogger(String name, Pair pair, RoboChannel channel)
      : super(name, pair, channel);

  log(Robocore bot, Swap swap) async {
    // Our pair?
    if (swap.pair == pair) {
      var wrapper = channel.getWrapperFromBot(bot);
      var core = pair.raw1(swap.amount1);
      print("WHALE: Checking sell whale: ${swap.sell} amount: $core");
      if (swap.sell && core > limit) {
        print("WHALE: Yes");
        int random = Random().nextInt(5) + 1; // 1-5
        var answer;
        //var hearts = makeBrokenHearts(eth);
        var hearts = makeSorrys(core, 190);
        if (wrapper is RoboDiscord) {
          answer = EmbedBuilder()
            ..title = "WHALE ALERT!"
            ..thumbnailUrl = "http://rey.krampe.se/whale${random}.jpg"
            ..addField(
                name:
                    ":whale: Sold ${dec2(pair.raw1(swap.amount1))} ${pair.token1name} for ${dec2(pair.raw2(swap.amount1Out))} ${pair.token2name}!",
                content:
                    ":chart_with_downwards_trend: [address](https://etherscan.io/address/${swap.sender}) [txn](https://etherscan.io/tx/${swap.tx})")
            ..addField(
                name: "Price now ${pair.priceString1()}", content: hearts)
            ..timestamp = DateTime.now().toUtc();
        } else {
          var hearts = makeSorrys(core, 1024);
          answer = """
🐳 <b>Sold ${dec2(pair.raw1(swap.amount1))} ${pair.token1name} for ${dec2(pair.raw2(swap.amount1Out))} ${pair.token2name}!</b> <a href=\"https://etherscan.io/address/${swap.sender}\">address</a> <a href=\"https://etherscan.io/tx/${swap.tx}\">txn</a>
$hearts
Price now ${pair.priceString1()}
""";
        }
        print("Posted whale logger to $channel, $answer");
        wrapper.send(channel.id, answer, disablePreview: true, markdown: false);
      }
    }
  }
}

class WhaleBuyLogger extends WhaleLogger {
  WhaleBuyLogger(String name, Pair pair, RoboChannel channel)
      : super(name, pair, channel);

  log(Robocore bot, Swap swap) async {
    // Our pair?
    if (swap.pair == pair) {
      var wrapper = channel.getWrapperFromBot(bot);
      var core = pair.raw1(swap.amount1);
      print("WHALE: Checking buy whale: ${swap.buy} amount: $core");
      if (swap.buy && core > limit) {
        int random = Random().nextInt(5) + 1; // 1-5
        var answer;
        var happies = makeHappies(core, 190);
        if (wrapper is RoboDiscord) {
          answer = EmbedBuilder()
            ..title = "WHALE ALERT!"
            ..thumbnailUrl = "http://rey.krampe.se/whale${random}.jpg"
            ..addField(
                name:
                    ":whale: Bought ${dec2(pair.raw1(swap.amount1))} ${pair.token1name} for ${dec2(pair.raw2(swap.amount1In))} ${pair.token2name}!",
                content:
                    ":chart_with_upwards_trend: [address](https://etherscan.io/address/${swap.to}) [txn](https://etherscan.io/tx/${swap.tx})")
            ..addField(
                name: "Price now ${pair.priceString1()}", content: happies)
            ..timestamp = DateTime.now().toUtc();
        } else {
          var hearts = makeHearts(core, 1024);
          answer = """
🐳 <b>Bought ${dec2(pair.raw1(swap.amount1))} ${pair.token1name} for ${dec2(pair.raw2(swap.amount1In))} ${pair.token2name}!</b> <a href=\"https://etherscan.io/address/${swap.to}\">address</a> <a href=\"https://etherscan.io/tx/${swap.tx}\">txn</a>
$hearts
Price now ${pair.priceString1()}
""";
        }
        print("Posted whale logger to $channel, $answer");
        wrapper.send(channel.id, answer, disablePreview: true, markdown: false);
      }
    }
  }
}
