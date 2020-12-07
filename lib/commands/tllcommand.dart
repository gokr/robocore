import 'package:robocore/chat/robomessage.dart';
import 'package:robocore/commands/command.dart';
import 'package:robocore/util.dart';

class TLLCommand extends Command {
  TLLCommand()
      : super("tll", "t", "tll|t",
            "Show current TLL (Total Liquidity Locked), TVPL (Total Value Permanently Locked) and total CORE supply.");

  @override
  handleMessage(RoboMessage w) async {
    await w.bot.updatePriceInfo(null);
    w
      ..addField("Total Liquidity Locked (TLL)", "${usd2(w.bot.TLLinUSD)}")
      ..addField(
          "Total Value Permanently Locked (TVPL)", "${usd2(w.bot.TVPLinUSD)}")
      ..addField("CORE burned", "${dec2(w.bot.COREburned)}")
      ..addField("Total CORE supply", "${dec2(w.bot.COREsupply)}");
    return await w.reply(w.answer);
  }
}
