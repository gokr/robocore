import 'dart:math';

import 'package:nyxx/nyxx.dart';
import 'package:robocore/core.dart';
import 'package:robocore/robocore.dart';
import 'package:robocore/model/swap.dart';

class EventLogger {
  late String name;
  ITextChannel channel;

  EventLogger(this.name, this.channel);

  log(Robocore bot, Swap swap) async {}

  String toString() => name;
}

class WhaleLogger extends EventLogger {
  num limit = 100;

  WhaleLogger(String name, ITextChannel channel) : super(name, channel);

  log(Robocore bot, Swap swap) async {
    if (raw18(swap.amount) > limit) {
      int random = Random().nextInt(5) + 1; // 1-5
      if (swap.sell) {
        final embed = EmbedBuilder()
          ..title = "WHALE ALERT!"
          ..thumbnailUrl = "http://rey.krampe.se/whale${random}.jpg"
          ..addField(
              name:
                  ":whale: Sold ${dec0(raw18(swap.amount0In))} CORE for **${dec0(raw18(swap.amount1Out))} ETH**!",
              content:
                  ":chart_with_downwards_trend: [address](https://etherscan.io/address/${swap.to}) [txn](https://etherscan.io/tx/${swap.tx})")
          ..timestamp = DateTime.now().toUtc();
        channel.send(embed: embed);
      } else {
        final embed = EmbedBuilder()
          ..title = "WHALE ALERT!"
          ..thumbnailUrl = "http://rey.krampe.se/whale${random}.jpg"
          ..addField(
              name:
                  ":whale: Bought ${dec0(raw18(swap.amount0Out))} CORE for **${dec0(raw18(swap.amount1In))} ETH**!",
              content:
                  ":chart_with_upwards_trend: [address](https://etherscan.io/address/${swap.to}) [txn](https://etherscan.io/tx/${swap.tx})")
          ..timestamp = DateTime.now().toUtc();
        channel.send(embed: embed);
      }
    }
  }
}

class PriceLogger extends EventLogger {
  num delta = 100;
  num lastPriceCOREinUSD = 0;

  PriceLogger(String name, ITextChannel channel) : super(name, channel);

  log(Robocore bot, Swap swap) async {
    // Did we move more than limit USD per CORE?
    if (lastPriceCOREinUSD != 0) {
      num diff = lastPriceCOREinUSD - bot.priceCOREinUSD;
      String arrow = diff.isNegative ? "UP" : "DOWN";
      if (diff.abs() > delta) {
        // Let's remember this
        lastPriceCOREinUSD = bot.priceCOREinUSD;
        final embed = EmbedBuilder()
          ..addAuthor((author) {
            author.name = "Price alert! Moved $arrow \$${dec0(diff.abs())}!";
          })
          ..addField(name: "Price CORE", content: bot.priceStringCORE())
          ..addField(name: "Price ETH", content: bot.priceStringETH())
          ..addField(name: "Price LP", content: bot.priceStringLP())
          ..timestamp = DateTime.now().toUtc();
        channel.send(embed: embed);
      }
    } else {
      lastPriceCOREinUSD = bot.priceCOREinUSD;
    }
  }
}

class SwapLogger extends EventLogger {
  SwapLogger(String name, ITextChannel channel) : super(name, channel);

  log(Robocore bot, Swap swap) async {
    if (swap.sell) {
      // Swapped CORE->ETH
      final embed = EmbedBuilder()
        ..addField(
            name:
                "Sold ${dec4(raw18(swap.amount0In))} CORE for ${dec4(raw18(swap.amount1Out))} ETH",
            content:
                ":chart_with_downwards_trend: [address](https://etherscan.io/address/${swap.to}) [txn](https://etherscan.io/tx/${swap.tx})")
        ..timestamp = DateTime.now().toUtc();
      channel.send(embed: embed);
    } else {
      // Swapped ETH->CORE
      final embed = EmbedBuilder()
        ..addField(
            name:
                "Bought ${dec2(raw18(swap.amount0Out))} CORE for ${dec2(raw18(swap.amount1In))} ETH",
            content:
                ":chart_with_upwards_trend: [address](https://etherscan.io/address/${swap.to}) [txn](https://etherscan.io/tx/${swap.tx})")
        ..timestamp = DateTime.now().toUtc();
      channel.send(embed: embed);
    }
  }
}
