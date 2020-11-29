import 'package:robocore/chat/robomessage.dart';
import 'package:robocore/commands/command.dart';
import 'package:robocore/model/contribution.dart';
import 'package:robocore/ethereum.dart';
import 'package:robocore/model/corebought.dart';
import 'package:robocore/util.dart';

class FakeCommand extends Command {
  FakeCommand() : super("fake", "", "fake", "Fake stuff.");

  @override
  handleMessage(RoboMessage w) async {
    var bot = w.bot;
    await bot.updateLGE3Info();
    var parts = w.parts;
    var amount = int.parse(parts[1]);
//    var c = Contribution(99, 3, DateTime.now(), ethereum.CORE.address, "tx",
//        BigInt.from(amount) * pow18, 'CORE', BigInt.from(0), null, "log", 0);
//    bot.logContribution(c);
    var c = CoreBought(
        99, 3, BigInt.from(amount) * pow18, ethereum.CORE.address, "tx");
    bot.logCoreBought(c);
    return await w.reply("done");
  }
}
