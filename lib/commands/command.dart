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
