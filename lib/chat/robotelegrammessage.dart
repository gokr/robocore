import 'package:markdown/markdown.dart';
import 'package:robocore/chat/robochannel.dart';
import 'package:robocore/chat/robomessage.dart';
import 'package:robocore/chat/robotelegram.dart';
import 'package:robocore/model/robouser.dart';
import 'package:robocore/chat/telegramchannel.dart';
import 'package:robocore/robocore.dart';
import 'package:robocore/util.dart';
import 'package:teledart/model.dart';

const telegramPrefix = "/";

class RoboTelegramMessage extends RoboTelegram with RoboMessage {
  TeleDartMessage e;
  late String text, textLowerCase;
  late List<String> parts;

  StringBuffer _answer = StringBuffer();

  RoboTelegramMessage(Robocore bot, this.e) : super(bot) {
    text = e.text;
    textLowerCase = text.toLowerCase();
    parts = splitMessage(textLowerCase);
  }

/*
  // In Telegram all commands are valid
  bool validCommand(Command cmd) {
    var text = e.text;p
    return text.startsWith(telegramPrefix + cmd.name) ||
        (cmd.short != "" && (text == telegramPrefix + cmd.short) ||
            text.startsWith(telegramPrefix + cmd.short + " "));
  }
*/
  String get prefix => telegramPrefix;

  String get username => e.from.username ?? "(you have no username!)";
  RoboUser get roboUser => RoboUser.telegram(e.from.id.toString());
  RoboChannel get roboChannel => TelegramChannel(e.chat.id);
  bool get isDirectChat => e.chat.type == "private";

  reply(dynamic answer, {bool disablePreview = true}) async {
    await e.reply(answer,
        parse_mode: 'HTML', disable_web_page_preview: disablePreview);
  }

  String buildHelp(RoboUser user) {
    StringBuffer buf = StringBuffer();
    for (var cmd in bot.commands) {
      if (cmd.validForUser(user)) {
        buf.writeln("<b>${cmd.name}</b>");
        buf.writeln("Syntax: <code>${cmd.syntax}</code>");
        buf.writeln("${cmd.help}");
        buf.writeln("");
      }
    }
    return buf.toString();
  }

  @override
  bool isMention() =>
      text.contains("@robocore_bot") || text.contains("@robocoretest_bot");

  @override
  addField(String label, String content) {
    _answer..writeln('<b>$label</b>')..writeln(content);
  }

  @override
  addFooter(String content) {
    _answer..writeln()..writeln(content);
  }

  @override
  finish() {
    // Nothing needed
  }

  @override
  dynamic get answer => _answer.toString().markdownToHTML();
}
