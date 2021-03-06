import 'package:nyxx/nyxx.dart';
import 'package:robocore/chat/robochannel.dart';
import 'package:robocore/chat/robodiscord.dart';
import 'package:robocore/loggers/eventlogger.dart';
import 'package:robocore/pair.dart';
import 'package:robocore/robocore.dart';
import 'package:robocore/model/swap.dart';
import 'package:robocore/util.dart';

class SwapLogger extends EventLogger {
  SwapLogger(String name, Pair pair, RoboChannel channel)
      : super(name, pair, channel);

  log(Robocore bot, Swap swap) async {
    var wrapper = channel.getWrapperFromBot(bot);
    var answer;
    if (swap.pair == pair) {
      if (swap.sell) {
        // Swapped CORE->ETH
        if (wrapper is RoboDiscord) {
          answer = EmbedBuilder()
            ..addField(
                name:
                    "Sold ${dec2(pair.raw1(swap.amount0In))} ${pair.token1name} for ${dec2(pair.raw2(swap.amount1Out))} ${pair.token2name}",
                content:
                    ":chart_with_downwards_trend: [address](https://etherscan.io/address/${swap.to}) [txn](https://etherscan.io/tx/${swap.tx})")
            ..timestamp = DateTime.now().toUtc();
        } else {
          answer = """
<b>Sold ${dec2(pair.raw1(swap.amount0In))} ${pair.token1name} for ${dec2(pair.raw2(swap.amount1Out))} ${pair.token2name}</b> ⬇️ <a href=\"https://etherscan.io/address/${swap.to}\">address</a> <a href="\https://etherscan.io/tx/${swap.tx}\">tx</a>
""";
        }
      } else {
        // Swapped ETH->CORE
        if (wrapper is RoboDiscord) {
          answer = EmbedBuilder()
            ..addField(
                name:
                    "Bought ${dec2(pair.raw1(swap.amount0Out))} ${pair.token1name} for ${dec2(pair.raw2(swap.amount1In))} ${pair.token2name}",
                content:
                    ":chart_with_upwards_trend: [address](https://etherscan.io/address/${swap.to}) [txn](https://etherscan.io/tx/${swap.tx})")
            ..timestamp = DateTime.now().toUtc();
        } else {
          answer = """
<b>Bought ${dec2(pair.raw1(swap.amount0Out))} ${pair.token1name} for ${dec2(pair.raw2(swap.amount1In))} ${pair.token2name}</b> ⬆️ <a href=\"https://etherscan.io/address/${swap.to}\">address</a> <a href="\https://etherscan.io/tx/${swap.tx}\">tx</a>
""";
        }
      }
      wrapper.send(channel.id, answer, markdown: false, disablePreview: true);
    }
  }
}
