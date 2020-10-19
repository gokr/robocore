import 'dart:math';

import 'package:nyxx/nyxx.dart';
import 'package:robocore/command.dart';
import 'package:robocore/core.dart';
import 'package:robocore/robocore.dart';
import 'package:robocore/model/swap.dart';
import 'package:robocore/util.dart';

class EventLogger {
  late String name;
  RoboChannel channel;

  EventLogger(this.name, this.channel);

  log(Robocore bot, Swap swap) async {}

  String toString() => name;
}

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

  log(Robocore bot, Swap swap) async {
    var wrapper = channel.getWrapperFromBot(bot);
    var eth = raw18(swap.amount);
    if (eth > limit) {
      int random = Random().nextInt(5) + 1; // 1-5
      var answer;
      if (swap.sell) {
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
      } else {
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
      }
      print("Posted whale logger to $channel, $answer");
      wrapper.send(channel.id, answer, disablePreview: true, markdown: false);
    }
  }
}

class PriceLogger extends EventLogger {
  num delta = 100;
  num lastPriceCOREinUSD = 0;

  PriceLogger(String name, RoboChannel channel) : super(name, channel);

  log(Robocore bot, Swap swap) async {
    var wrapper = channel.getWrapperFromBot(bot);
    // Did we move more than limit USD per CORE?
    if (lastPriceCOREinUSD != 0) {
      num diff = lastPriceCOREinUSD - bot.priceCOREinUSD;
      String arrow = diff.isNegative ? "UP" : "DOWN";
      if (diff.abs() > delta) {
        // Let's remember this
        lastPriceCOREinUSD = bot.priceCOREinUSD;
        var answer;
        if (wrapper is RoboDiscord) {
          answer = EmbedBuilder()
            ..addAuthor((author) {
              author.name = "Price alert! Moved $arrow \$${dec0(diff.abs())}!";
            })
            ..addField(name: "Price CORE", content: bot.priceStringCORE())
            ..addField(name: "Price ETH", content: bot.priceStringETH())
            ..addField(name: "Price LP", content: bot.priceStringLP())
            ..timestamp = DateTime.now().toUtc();
        } else {
          answer = """
<b>Price alert! Moved $arrow \$${dec0(diff.abs())}!</b>
<b>Price CORE:</b> ${bot.priceStringCORE()}
<b>Price ETH:</b> ${bot.priceStringETH()}
<b>Price LP:</b> ${bot.priceStringLP()}
""";
        }
        wrapper.send(channel.id, answer, markdown: false);
      }
    } else {
      lastPriceCOREinUSD = bot.priceCOREinUSD;
    }
  }
}

class SwapLogger extends EventLogger {
  SwapLogger(String name, RoboChannel channel) : super(name, channel);

  log(Robocore bot, Swap swap) async {
    var wrapper = channel.getWrapperFromBot(bot);
    var answer;
    if (swap.sell) {
      // Swapped CORE->ETH
      if (wrapper is RoboDiscord) {
        answer = EmbedBuilder()
          ..addField(
              name:
                  "Sold ${dec4(raw18(swap.amount0In))} CORE for ${dec4(raw18(swap.amount1Out))} ETH",
              content:
                  ":chart_with_downwards_trend: [address](https://etherscan.io/address/${swap.to}) [txn](https://etherscan.io/tx/${swap.tx})")
          ..timestamp = DateTime.now().toUtc();
      } else {
        answer = """
<b>Sold ${dec4(raw18(swap.amount0In))} CORE for ${dec4(raw18(swap.amount1Out))} ETH</b> ⬇️ <a href=\"https://etherscan.io/address/${swap.to}\">address</a> <a href="\https://etherscan.io/tx/${swap.tx}\">tx</a>
""";
      }
    } else {
      // Swapped ETH->CORE
      if (wrapper is RoboDiscord) {
        answer = EmbedBuilder()
          ..addField(
              name:
                  "Bought ${dec2(raw18(swap.amount0Out))} CORE for ${dec2(raw18(swap.amount1In))} ETH",
              content:
                  ":chart_with_upwards_trend: [address](https://etherscan.io/address/${swap.to}) [txn](https://etherscan.io/tx/${swap.tx})")
          ..timestamp = DateTime.now().toUtc();
      } else {
        answer = """
<b>Bought ${dec2(raw18(swap.amount0Out))} CORE for ${dec2(raw18(swap.amount1In))} ETH</b> ⬆️ <a href=\"https://etherscan.io/address/${swap.to}\">address</a> <a href="\https://etherscan.io/tx/${swap.tx}\">tx</a>
""";
      }
    }
    wrapper.send(channel.id, answer, markdown: false, disablePreview: true);
  }
}
