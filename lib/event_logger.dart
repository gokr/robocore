import 'dart:math';

import 'package:nyxx/nyxx.dart';
import 'package:robocore/command.dart';
import 'package:robocore/core.dart';
import 'package:robocore/robocore.dart';
import 'package:robocore/model/swap.dart';

class EventLogger {
  late String name;
  RoboChannel channel;

  EventLogger(this.name, this.channel);

  log(RoboWrapper bot, Swap swap) async {}

  String toString() => name;
}

class WhaleLogger extends EventLogger {
  // Amount in ETH
  num limit = 200;

  WhaleLogger(String name, RoboChannel channel) : super(name, channel);

  log(RoboWrapper wrapper, Swap swap) async {
    if (raw18(swap.amount) > limit) {
      int random = Random().nextInt(5) + 1; // 1-5
      var answer;
      if (swap.sell) {
        if (wrapper is RoboDiscord) {
          answer = EmbedBuilder()
            ..title = "WHALE ALERT!"
            ..thumbnailUrl = "http://rey.krampe.se/whale${random}.jpg"
            ..addField(
                name:
                    ":whale: Sold ${dec0(raw18(swap.amount0In))} CORE for **${dec0(raw18(swap.amount1Out))} ETH**!",
                content:
                    ":chart_with_downwards_trend: [address](https://etherscan.io/address/${swap.to}) [txn](https://etherscan.io/tx/${swap.tx})")
            ..timestamp = DateTime.now().toUtc();
        } else {
          answer = """
🐳 Sold ${dec0(raw18(swap.amount0In))} CORE for *${dec0(raw18(swap.amount1Out))} ETH*\!
[address](https://etherscan.io/address/${swap.to}) [txn](https://etherscan.io/tx/${swap.tx})
""";
        }
      } else {
        if (wrapper is RoboDiscord) {
          answer = EmbedBuilder()
            ..title = "WHALE ALERT!"
            ..thumbnailUrl = "http://rey.krampe.se/whale${random}.jpg"
            ..addField(
                name:
                    ":whale: Bought ${dec0(raw18(swap.amount0Out))} CORE for *${dec0(raw18(swap.amount1In))} ETH*!",
                content:
                    ":chart_with_upwards_trend: [address](https://etherscan.io/address/${swap.to}) [txn](https://etherscan.io/tx/${swap.tx})")
            ..timestamp = DateTime.now().toUtc();
        } else {
          answer = """
🐳 Bought ${dec0(raw18(swap.amount0Out))} CORE for *${dec0(raw18(swap.amount1In))} ETH*\!
[address](https://etherscan.io/address/${swap.to}) [txn](https://etherscan.io/tx/${swap.tx})
""";
        }
      }
      wrapper.send(channel.id, answer);
    }
  }
}

class PriceLogger extends EventLogger {
  num delta = 100;
  num lastPriceCOREinUSD = 0;

  PriceLogger(String name, RoboChannel channel) : super(name, channel);

  log(RoboWrapper wrapper, Swap swap) async {
    var bot = wrapper.bot;
    // Did we move more than limit USD per CORE?
    if (lastPriceCOREinUSD != 0) {
      num diff = lastPriceCOREinUSD - bot.priceCOREinUSD;
      String arrow = diff.isNegative ? "UP" : "DOWN";
      if (diff.abs() > delta) {
        // Let's remember this
        lastPriceCOREinUSD = bot.priceCOREinUSD;
        var answer;
        if (bot is RoboDiscord) {
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
*Price alert\! Moved $arrow \$${dec0(diff.abs())}\!*
*Price CORE:* ${bot.priceStringCORE()}
*Price ETH:* ${bot.priceStringETH()}
*Price LP:* ${bot.priceStringLP()}
""";
        }
        wrapper.send(channel.id, answer);
      }
    } else {
      lastPriceCOREinUSD = bot.priceCOREinUSD;
    }
  }
}

class SwapLogger extends EventLogger {
  SwapLogger(String name, RoboChannel channel) : super(name, channel);

  log(RoboWrapper wrapper, Swap swap) async {
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
*Sold ${dec4(raw18(swap.amount0In))} CORE for ${dec4(raw18(swap.amount1Out))} ETH*
⬇️ [address](https://etherscan.io/address/${swap.to}) [txn](https://etherscan.io/tx/${swap.tx})
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
*Bought ${dec2(raw18(swap.amount0Out))} CORE for ${dec2(raw18(swap.amount1In))} ETH*
⬆️ [address](https://etherscan.io/address/${swap.to}) [txn](https://etherscan.io/tx/${swap.tx})
""";
      }
    }
    wrapper.send(channel.id, answer);
  }
}
