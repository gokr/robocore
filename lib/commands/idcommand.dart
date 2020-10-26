import 'package:robocore/chat/robomessage.dart';
import 'package:robocore/commands/command.dart';

class IdCommand extends Command {
  IdCommand() : super("id", "", "id", "Show chat id and user id.");

  @override
  handleMessage(RoboMessage bot) async {
    return await bot
        .reply("Channel id: ${bot.roboChannel} User id: ${bot.roboUser}");
  }
}
