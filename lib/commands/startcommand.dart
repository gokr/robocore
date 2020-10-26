import 'package:robocore/chat/robomessage.dart';
import 'package:robocore/commands/command.dart';

class StartCommand extends Command {
  StartCommand()
      : super("start", "", "start",
            "Just say hi and get things going! Standard procedure in Telegram, not used in Discord really.");

  @override
  handleMessage(RoboMessage bot) async {
    return bot.reply("Well, hi there ${bot.username}! What can I do for you?");
  }
}
