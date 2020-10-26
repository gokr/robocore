import 'package:robocore/chat/robomessage.dart';
import 'package:robocore/commands/command.dart';

class AdminCommand extends Command {
  AdminCommand()
      : super("admin", "a", "admin|a", "Special RoboCORE admin stuff.");

  @override
  handleMessage(RoboMessage bot) async {
    var parts = bot.parts;
    // channel = Show this channel
    if (parts.length == 1) {
      return await bot.reply("Need sub command");
    }
    if (parts[1] == "channelid") {
      return await bot.reply("Channel id: ${bot.roboChannel}");
    }
  }
}
