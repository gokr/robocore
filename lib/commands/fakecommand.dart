import 'dart:math';

import 'package:robocore/chat/robomessage.dart';
import 'package:robocore/commands/command.dart';
import 'package:robocore/model/contribution.dart';
import 'package:robocore/ethereum.dart';
import 'package:robocore/model/corebought.dart';
import 'package:robocore/util.dart';
import 'package:web3dart/web3dart.dart';

class FakeCommand extends Command {
  FakeCommand() : super("fake", "", "fake", "Fake stuff.");

  @override
  handleMessage(RoboMessage w) async {
    var bot = w.bot;
    await bot.updateLGE3Info();
    var parts = w.parts;
    var contrib = parts[3];
    if (contrib == "contrib") {
      var tx = parts[2];
      var sender = parts[3];
      var amount = parts[4];
      var coreValue = BigInt.from(
          (raw18(BigInt.parse(amount)) / bot.priceCOREinETH) * pow(10, 18));
      var contrib = Contribution.fromWETHDeposit(
          3, tx, coreValue, EthereumAddress.fromHex(sender));
      await bot.logContribution(contrib);
      await contrib.insert();
    } else {
      var tx = parts[2];
      var sender = parts[3];
      var amount = parts[4];
      var coreValue = BigInt.parse(amount);
      var cb =
          CoreBought(99, 3, coreValue, EthereumAddress.fromHex(sender), tx);
      await bot.logCoreBought(cb);
      await cb.insert();
    }
    return await w.reply("done");
  }
}
