import 'package:nyxx/nyxx.dart';
import 'package:robocore/chat/robochannel.dart';
import 'package:robocore/chat/robodiscord.dart';
import 'package:robocore/loggers/eventlogger.dart';
import 'package:robocore/pair.dart';
import 'package:robocore/robocore.dart';
import 'package:robocore/model/swap.dart';
import 'package:robocore/util.dart';

class PriceLogger extends EventLogger {
  num delta = 10;
  num lastPrice = 0;

  PriceLogger(String name, Pair pair, RoboChannel channel)
      : super(name, pair, channel);

  log(Robocore bot, Swap swap) async {
    var wrapper = channel.getWrapperFromBot(bot);
    // Our pair?
    if (swap.pair == pair) {
      // Did we move more than limit percent?
      if (lastPrice != 0) {
        num percent = ((lastPrice - pair.price1).abs() / lastPrice) * 100;
        String arrow = (lastPrice - pair.price1).isNegative ? "UP" : "DOWN";
        if (percent > delta) {
          // Let's remember this
          lastPrice = pair.price1;
          var t1 = pair.token1name;
          var t2 = pair.token2name;

          var answer;
          if (wrapper is RoboDiscord) {
            answer = EmbedBuilder()
              ..addAuthor((author) {
                author.name = "Price alert! Moved $arrow ${dec2(percent)}%!";
              })
              ..addField(name: "Price $t1", content: pair.priceString1())
              ..addField(name: "Price $t2", content: pair.priceString2())
              ..timestamp = DateTime.now().toUtc();
          } else {
            answer = """
<b>Price alert! Moved $arrow ${dec2(percent)}%!</b>
<b>Price $t1:</b> ${pair.priceString1()}
<b>Price $t2:</b> ${pair.priceString2()}
""";
          }
          wrapper.send(channel.id, answer, markdown: false);
        }
      } else {
        lastPrice = pair.price1;
      }
    }
  }

  String toString() => "$name($pair, >$delta%)";
}
