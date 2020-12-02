import 'package:robocore/chat/robomessage.dart';
import 'package:robocore/commands/command.dart';
import 'package:robocore/model/robouser.dart';
import 'package:robocore/robocore.dart';

class ImpostorDetectorCommand extends Command {
  ImpostorDetectorCommand()
      : super("impostor", "", "impostor", "List potential impostors");

  // I am valid for all messages, because I check ids of users
  bool isValid(RoboMessage bot) {
    return true;
  }

  @override
  handleMessage(RoboMessage msg) async {
    var user = msg.roboUser;
    if (user.isImpostor(msg)) {
      await msg.bot.discord.send(moderatorChannel.id,
          "The user ${user.username} is a likely impostor.",
          markdown: false);
    }
  }

  @override
  String get command => " @RoboCORE";
}
