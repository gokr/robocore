import 'package:robocore/chat/robomessage.dart';
import 'package:robocore/commands/command.dart';
import 'package:robocore/model/robouser.dart';
import 'package:robocore/robocore.dart';

class ImpostorDetectorCommand extends Command {
  ImpostorDetectorCommand()
      : super(
            "impostor", "", "impostor", "List potential impostors, only admin");

  @override
  handleMessage(RoboMessage msg) async {
    var parts = msg.parts;
    // Only !impostor
    if (parts.length == 1) {
      //TODO: List?
    }
    if (parts.length == 2) {
      var name = parts[1];
      List<RoboUser> fuzzyMatches = await RoboUser.findFuzzyUsers(name);
      if (fuzzyMatches.isNotEmpty) {
        await msg.reply("$fuzzyMatches");
      }
    }
  }

  @override
  String get command => " @RoboCORE";
}
