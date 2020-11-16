import 'package:nyxx/nyxx.dart';
import 'package:robocore/chat/robochannel.dart';
import 'package:robocore/chat/robomessage.dart';
import 'package:robocore/model/robouser.dart';
import 'package:robocore/robocore.dart';
import 'package:robocore/robowrapper.dart';

class RoboFakeMessage extends RoboWrapper with RoboMessage {
  late String text, textLowerCase;
  late List<String> parts;

  RoboUser user;
  RoboChannel channel;

  RoboFakeMessage(Robocore bot, String tx, this.channel, this.user)
      : super(bot) {
    text = tx;
    textLowerCase = text.toLowerCase();
    parts = splitMessage(textLowerCase);
  }

  String get prefix => "!";

  String get username => "fake";
  RoboUser get roboUser => user;
  RoboChannel get roboChannel => channel;
  bool get isDirectChat => false;

  DiscordColor color() {
    return DiscordColor.black;
  }

  bool isMention() => false;

  @override
  addField(String label, String content) {
    // TODO: implement addField
    throw UnimplementedError();
  }

  @override
  addFooter(String content) {
    // TODO: implement addFooter
    throw UnimplementedError();
  }

  @override
  buildHelp() {
    // TODO: implement buildHelp
    throw UnimplementedError();
  }

  @override
  finish() {
    // TODO: implement finish
    throw UnimplementedError();
  }
}
