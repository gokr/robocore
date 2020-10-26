import 'package:robocore/chat/robomessage.dart';
import 'package:robocore/commands/command.dart';
import 'package:robocore/loggers/pricelogger.dart';
import 'package:robocore/loggers/swaplogger.dart';
import 'package:robocore/loggers/whalelogger.dart';

class LogCommand extends Command {
  LogCommand()
      : super(
            "log",
            "l",
            "log|l add|remove core-eth|core-cbtc [whalebuy|whalesell [limit] | swap | price [delta] | all]",
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
    if (parts.length < 4) {
      return await msg.reply("Use $syntax");
    }
    if (parts.length >= 4) {
      if (!["add", "remove"].contains(parts[1])) {
        return await msg.reply("Use $syntax");
      }
      bool add = parts[1] == "add";
      var pairname = parts[2];
      var pair = bot.ethereum.findPair(pairname.toLowerCase());
      if (pair == null) {
        return await msg.reply(
            "Could not find pair $pairname, use one of ${bot.ethereum.pairNames()}");
      }
      var names = parts.sublist(3);
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
          switch (name) {
            case "whalebuy":
              if (add) {
                var logger = WhaleBuyLogger("whalebuy", pair, ch);
                if (arg != null) logger.limit = arg;
                bot.addLogger(logger);
              } else {
                bot.removeLogger("whalebuy", ch);
              }
              break;
            case "whalesell":
              if (add) {
                var logger = WhaleSellLogger("whalesell", pair, ch);
                if (arg != null) logger.limit = arg;
                bot.addLogger(logger);
              } else {
                bot.removeLogger("whalesell", ch);
              }
              break;
            case "price":
              if (add) {
                var logger = PriceLogger("price", pair, ch);
                if (arg != null) logger.delta = arg;
                bot.addLogger(logger);
              } else {
                bot.removeLogger("price", ch);
              }
              break;
            case "swap":
              if (add) {
                bot.addLogger(SwapLogger("swap", pair, ch));
              } else {
                bot.removeLogger("swap", ch);
              }
              break;
            case "all":
              bot.removeLoggers(ch);
              if (add) {
                bot.addLogger(PriceLogger("price", pair, ch));
                bot.addLogger(SwapLogger("swap", pair, ch));
                bot.addLogger(WhaleBuyLogger("whalebuy", pair, ch));
                bot.addLogger(WhaleSellLogger("whalesell", pair, ch));
              }
              break;
          }
        } else {
          arg = null;
        }
      }
    }
    String active = bot.loggersFor(ch).join(" ");
    return await msg.reply("Active loggers: $active");
  }
}
