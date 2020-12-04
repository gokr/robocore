import 'package:robocore/chat/robochannel.dart';
import 'package:robocore/model/robouser.dart';
import 'package:robocore/commands/command.dart';
import 'package:robocore/config.dart';
import 'package:robocore/robowrapper.dart';
import 'package:robocore/util.dart';

mixin RoboMessage on RoboWrapper {
  /// Find a Command valid for this message and let it handle it
  runCommands() async {
    logMessage();
    // Let all commands valid handle the message (may be more than one)
    for (var cmd in bot.commands) {
      if (cmd.isValid(this)) {
        await cmd.handleMessage(this);
      }
    }
    // Was it still a command? We don't reply on commands we don't recognize
    // if (isCommand()) reply(randomDNU());
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
    var did = roboUser.discordId;
    var tid = roboUser.telegramId;
    var nick = roboUser.nickname;
    log.info("$roboChannel ($username<$did,$tid>, $nick): $text");
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

  /// Answer construction
  addField(String label, String content);
  addFooter(String content);
  finish();
  dynamic answer;

  reply(dynamic answer, {bool disablePreview = true}) async {}

  dynamic buildHelp(RoboUser roboUser);
}
