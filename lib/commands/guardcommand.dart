import 'package:robocore/chat/robomessage.dart';
import 'package:robocore/commands/command.dart';
import 'package:robocore/ethereum.dart';
import 'package:robocore/util.dart';

class GuardCommand extends Command {
  GuardCommand()
      : super("guard", "", "guard address",
            "Install a guard on an Ethereum address.");

  @override
  handleMessage(RoboMessage w) async {
    var parts = w.parts;
    // Only !pair
    if (parts.length == 1) {
      // List guards
    }
    if (parts.length > 2) {
      // Add guard
    }
  }
}
