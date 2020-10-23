import 'package:nyxx/nyxx.dart';
import 'package:robocore/command.dart';
import 'package:robocore/core.dart';
import 'package:robocore/loggers/eventlogger.dart';
import 'package:robocore/robocore.dart';
import 'package:robocore/model/swap.dart';

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
