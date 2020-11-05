import 'package:robocore/chat/robochannel.dart';
import 'package:robocore/chat/robodiscordmessage.dart';
import 'package:robocore/chat/robomessage.dart';
import 'package:robocore/model/robouser.dart';
import 'package:robocore/robocore.dart';

abstract class Command {
  String name, short, syntax, help;
  List<RoboChannel> blacklist = [];
  List<RoboChannel> whitelist = [];
  List<RoboUser> users = [];

  /// Is this command fine for everyone, if executed in direct chat?
  bool validForAllInDM = true;

  Command(this.name, this.short, this.syntax, this.help);

  /// Handle the message
  handleMessage(RoboMessage bot);

  /// Handle the command, returns a String if handled, otherwise null
  Future<String?> inlineTelegram(String cmd, Robocore robot) async {
    return null;
  }

  /// Either whitelisted or blacklisted (can't be both)
  bool validForChannel(RoboChannel ch) {
    if (whitelist.isNotEmpty) {
      return whitelist.contains(ch);
    } else {
      return !blacklist.contains(ch);
    }
  }

  /// If a command is valid for given user
  bool validForUser(RoboUser user) {
    return users.isEmpty || users.contains(user);
  }

  /// Is this Command valid to execute for this message? Double dispatch
  bool isValid(RoboMessage bot) {
    return bot.validCommand(this);
  }

  String get command => "$discordPrefix$name";
  String get shortCommand => "$discordPrefix$short";
}

/*
class StickyCommand extends Command {
  StickyCommand(name, short, syntax, help) : super(name, short, syntax, help);

  @override
  Future<bool> execDiscord(MessageReceivedEvent e, Robocore robot) async {
    if (_validDiscord(e)) {
      _logDiscordCommand(e);
      var parts = splitMessage(e);
      String? name, sticky;
      // Only !sticky
      if (parts.length == 1) {
        await e.message.channel.send(
            content: "Use for example !sticky mysticky \"Yaddayadd, blabla\"");
        return true;
      }
      // Also name given
      if (parts.length == 2) {
        await e.message.channel.send(
            content: "Use for example !sticky mysticky \"Yaddayadd, blabla\"");
        return true;
      } else {
        name = parts[2];
        sticky = parts[3];
        // Remove "" around sticky
        if (sticky.startsWith("\"")) {
          sticky = sticky.substring(1, sticky.length - 1);
        }
      }
      // Create or update sticky with name
      var snowflake = robot.stickies[name];
      if (snowflake != null) {
        var sticky = await e.message.channel.getMessage(snowflake);
      } else {
        // Create it
        Message()
        await e.message.channel.send(
            content: "No sticky called $name found");
        return true;
      }
      sticky.
      return true;
    }
    return false;
  }

  @override
  Future<bool> execTelegram(TeleDartMessage message, Robocore robot) async {
    if (_validTelegram(message)) {
      await message.reply("not yet fixed for Telegram");
      return true;
    }
    return false;
  }
}
*/
/*class AliasesCommand extends Command {
  PriceCommand()
      : super("alias", "", "alias [remove \"foo\"|add \"foo\" \"bar\"]",
            "Manage aliases for longer commands, in this channel. Running only alias shows existing aliases.");
}*/
