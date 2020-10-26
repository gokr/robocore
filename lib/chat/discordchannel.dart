import 'package:robocore/chat/robochannel.dart';
import 'package:robocore/robocore.dart';
import 'package:robocore/robowrapper.dart';

class DiscordChannel extends RoboChannel {
  DiscordChannel(int id) : super(id);

  @override
  bool operator ==(other) {
    if (other is DiscordChannel) return other.id == this.id;
    if (other is int) return other == this.id;
    if (other is String) return other == this.id.toString();
    return false;
  }

  String toString() => "DiscordChannel($id)";

  @override
  RoboWrapper getWrapperFromBot(Robocore bot) {
    return bot.discord;
  }
}
