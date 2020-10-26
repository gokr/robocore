import 'package:robocore/robocore.dart';

abstract class RoboWrapper {
  Robocore bot;

  RoboWrapper(this.bot);

  Future<dynamic> getChannelOrChat(int id) async {}

  Future<int?> send(int channelOrChatId, dynamic content,
      {bool disablePreview = true, bool markdown = true}) async {}

  Future pinMessage(int channelOrChatId, int id) async {}

  Future<dynamic> getMessage(int channelOrChatId, int id) async {}

  Future<dynamic> editMessage(int channel, int id, dynamic content) async {}

  deleteMessage(int channelOrChatId, int id) async {}

  /// Split a message into distinct words and 'A sentence' or '<some JSON>'
  List<String> splitMessage(String str) {
    return exp.allMatches(str).map((m) => m.group(0) ?? "").toList();
  }

  /// Used to split messages so that parts can be in single quotes (like JSON)
  static final exp = RegExp("[^\\s']+|'[^']*'");
}
