import 'package:robocore/chat/robomessage.dart';
import 'package:robocore/commands/command.dart';

class HelpCommand extends Command {
  HelpCommand()
      : super("help", "h", "help|h", "Show all commands of RoboCORE.");

  @override
  handleMessage(RoboMessage bot) async {
    return await bot.reply(bot.buildHelp(bot.roboUser));
  }
}
