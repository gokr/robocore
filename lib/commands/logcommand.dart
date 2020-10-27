import 'package:robocore/chat/robomessage.dart';
import 'package:robocore/commands/command.dart';
import 'package:robocore/loggers/pricelogger.dart';
import 'package:robocore/loggers/swaplogger.dart';
import 'package:robocore/loggers/whalelogger.dart';
import 'package:robocore/pair.dart';

class LogCommand extends Command {
  LogCommand()
      : super(
            "log",
            "l",
            "log|l   add core-eth|core-cbtc (whalebuy|whalesell [limit] | swap | price [percent])  |  remove 'name'  |  removeall ]",
            "Control logging of events in current channel, only log will show active loggers. Only works in private conversations with RoboCORE, or in select channels on Discord.");

  @override
  handleMessage(RoboMessage msg) async {
    var bot = msg.bot;
    var ch = msg.roboChannel;
    var parts = msg.parts;
    var loggers = msg.bot.loggers.where((logger) => logger.channel == ch);
    // log = shows loggers
    // log remove all = removes all
    // log add|remove xxx = adds or removes logger
    if (parts.length == 1) {
      String active = loggers.join(" ");
      return await msg.reply("Active loggers: $active");
    }
    if (parts.length < 2) {
      return await msg.reply("Use $syntax");
    }
    if (parts.length >= 2) {
      if (!["add", "remove", "removeall"].contains(parts[1])) {
        return await msg.reply("Use $syntax");
      }
      if (parts[1] == "removeall") {
        bot.removeLoggers(ch);
      } else {
        bool add = parts[1] == "add";
        var names;
        Pair? pair;
        if (add) {
          var pairname = parts[2];
          pair = bot.ethereum.findCOREPair(pairname.toLowerCase());
          if (pair == null) {
            return await msg.reply(
                "Could not find pair $pairname, use one of ${bot.ethereum.corePairNames()}");
          }
          names = parts.sublist(3);
        } else {
          names = parts.sublist(2);
        }
        num? arg;
        for (int i = 0; i < names.length; i++) {
          var name = names[i];
          // If arg
          if (arg == null) {
            // One lookahead
            if (i < names.length - 1) {
              arg = num.tryParse(names[i + 1]);
            } else {
              arg = null;
            }
            var number = bot.loggersFor(ch).length + 1;
            if (name.startsWith("whalebuy")) {
              if (add) {
                var logger =
                    WhaleBuyLogger("whalebuy$number", pair as Pair, ch);
                if (arg != null) logger.limit = arg;
                bot.addLogger(logger);
              } else {
                bot.removeLogger(name, ch);
              }
            } else if (name.startsWith("whalesell")) {
              if (add) {
                var logger =
                    WhaleSellLogger("whalesell$number", pair as Pair, ch);
                if (arg != null) logger.limit = arg;
                bot.addLogger(logger);
              } else {
                bot.removeLogger(name, ch);
              }
            } else if (name.startsWith("price")) {
              if (add) {
                var logger = PriceLogger("price$number", pair as Pair, ch);
                if (arg != null) logger.delta = arg;
                bot.addLogger(logger);
              } else {
                bot.removeLogger(name, ch);
              }
            } else if (name.startsWith("swap")) {
              if (add) {
                bot.addLogger(SwapLogger("swap$number", pair as Pair, ch));
              } else {
                bot.removeLogger(name, ch);
              }
            }
          } else {
            arg = null;
          }
        }
      }
    }
    String active = bot.loggersFor(ch).join(" ");
    return await msg.reply("Active loggers: $active");
  }
}
