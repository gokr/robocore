import 'dart:math';

import 'package:nyxx/nyxx.dart';
import 'package:robocore/command.dart';
import 'package:robocore/core.dart';
import 'package:robocore/loggers/eventlogger.dart';
import 'package:robocore/robocore.dart';
import 'package:robocore/model/swap.dart';
import 'package:robocore/util.dart';

class WhaleLogger extends EventLogger {
  // Amount in ETH
  num limit = 200;

  WhaleLogger(String name, RoboChannel channel) : super(name, channel);

  String makeHearts(num eth, int limit) {
    return makeRepeatedString(eth.round(), "💚", limit);
  }

  String makeBrokenHearts(num eth, int limit) {
    return makeRepeatedString(eth.round(), "💔", limit);
  }

  // For Discord
  String makeBadges(num core, int limit) {
    var char = ["🛡️", "💚", "🎈", "🎂"].pickRandom();
    return makeRepeatedString(core.round(), char, limit);
  }
}

class WhaleSellLogger extends WhaleLogger {
  WhaleSellLogger(String name, RoboChannel channel) : super(name, channel);

  log(Robocore bot, Swap swap) async {
    var wrapper = channel.getWrapperFromBot(bot);
    var eth = raw18(swap.amount);
    if (swap.sell && eth > limit) {
      int random = Random().nextInt(5) + 1; // 1-5
      var answer;
      //var hearts = makeBrokenHearts(eth);
      var hearts = makeBrokenHearts(raw18(swap.amount0In), 190);
      if (wrapper is RoboDiscord) {
        answer = EmbedBuilder()
          ..title = "WHALE ALERT!"
          ..thumbnailUrl = "http://rey.krampe.se/whale${random}.jpg"
          ..addField(
              name:
                  ":whale: Sold ${dec2(raw18(swap.amount0In))} CORE for ${dec2(raw18(swap.amount1Out))} ETH!",
              content:
                  ":chart_with_downwards_trend: [address](https://etherscan.io/address/${swap.to}) [txn](https://etherscan.io/tx/${swap.tx})")
          ..addField(
              name: "Price now ${usd2(bot.priceCOREinUSD)}", content: hearts)
          ..timestamp = DateTime.now().toUtc();
      } else {
        var hearts = makeBrokenHearts(eth, 1024);
        answer = """
🐳 <b>Sold ${dec2(raw18(swap.amount0In))} CORE for ${dec2(raw18(swap.amount1Out))} ETH!</b> <a href=\"https://etherscan.io/address/${swap.to}\">address</a> <a href=\"https://etherscan.io/tx/${swap.tx}\">txn</a>
$hearts
Price now ${usd2(bot.priceCOREinUSD)}
""";
      }
      print("Posted whale logger to $channel, $answer");
      wrapper.send(channel.id, answer, disablePreview: true, markdown: false);
    }
  }
}

class WhaleBuyLogger extends WhaleLogger {
  WhaleBuyLogger(String name, RoboChannel channel) : super(name, channel);

  log(Robocore bot, Swap swap) async {
    var wrapper = channel.getWrapperFromBot(bot);
    var eth = raw18(swap.amount);
    if (swap.buy && eth > limit) {
      int random = Random().nextInt(5) + 1; // 1-5
      var answer;
      var vaults = makeBadges(raw18(swap.amount0Out), 190);
      if (wrapper is RoboDiscord) {
        answer = EmbedBuilder()
          ..title = "WHALE ALERT!"
          ..thumbnailUrl = "http://rey.krampe.se/whale${random}.jpg"
          ..addField(
              name:
                  ":whale: Bought ${dec2(raw18(swap.amount0Out))} CORE for ${dec2(raw18(swap.amount1In))} ETH!",
              content:
                  ":chart_with_upwards_trend: [address](https://etherscan.io/address/${swap.to}) [txn](https://etherscan.io/tx/${swap.tx})")
          ..addField(
              name: "Price now ${usd2(bot.priceCOREinUSD)}", content: vaults)
          ..timestamp = DateTime.now().toUtc();
      } else {
        var hearts = makeHearts(eth, 1024);
        answer = """
🐳 <b>Bought ${dec2(raw18(swap.amount0Out))} CORE for ${dec2(raw18(swap.amount1In))} ETH!</b> <a href=\"https://etherscan.io/address/${swap.to}\">address</a> <a href=\"https://etherscan.io/tx/${swap.tx}\">txn</a>
$hearts
Price now ${usd2(bot.priceCOREinUSD)}
""";
      }
      print("Posted whale logger to $channel, $answer");
      wrapper.send(channel.id, answer, disablePreview: true, markdown: false);
    }
  }
}
