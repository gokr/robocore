import 'package:robocore/chat/robochannel.dart';
import 'package:robocore/chat/robouser.dart';
import 'package:robocore/commands/command.dart';
import 'package:robocore/config.dart';
import 'package:robocore/robowrapper.dart';
import 'package:robocore/util.dart';

mixin RoboMessage on RoboWrapper {
  /// Find a Command valid for this message and let it handle it
  runCommands() async {
    logMessage();
    for (var cmd in bot.commands) {
      if (cmd.isValid(this)) {
        return await cmd.handleMessage(this);
      }
    }
    if (isCommand()) reply(randomDNU());
  }

  String randomDNU() {
    return [
      "I am afraid I can't do that Dave, I mean... ${username}",
      "I have absolutely no clue what you are blabbering about",
      "Are you sure I am meant to understand that?",
      "I am no damn AI, what did you mean?",
    ].pickRandom();
  }

  logMessage() {
    log.info("$roboChannel ($username): $text");
  }

  bool isCommand() {
    return text.startsWith(prefix);
  }

  bool isMention();

  /// Either ! or /
  String get prefix;

  // Is this command valid to execute for this message?
  bool validCommand(Command cmd) {
    // Some commands are valid for all in DM, or for select users with access
    if (isDirectChat) {
      return (cmd.validForAllInDM || cmd.validForUser(roboUser)) &&
          matches(cmd);
    } else {
      // Otherwise we check whitelist/blacklist of channel ids && users with access
      return cmd.validForChannel(roboChannel) &&
          cmd.validForUser(roboUser) &&
          matches(cmd);
    }
  }

  bool matches(Command cmd) {
    return (text.startsWith(prefix + cmd.name) ||
        (cmd.short != "" && (text == prefix + cmd.short) ||
            text.startsWith(prefix + cmd.short + " ")));
  }

  /// The actual message text
  String get text;
  String get textLowerCase;

  List<String> get parts;

  /// Returns a channel (Discord) or chat (Telegram)
  RoboChannel get roboChannel;

  /// Returns a RoboUser
  RoboUser get roboUser;

  /// Username of sender
  String get username;

  /// Is this a Direct Chat (DM. PM)?
  bool get isDirectChat;

  reply(dynamic answer,
      {bool disablePreview = true, bool markdown = false}) async {}

  dynamic buildHelp();
}
