import 'package:robocore/robocore.dart';
import 'package:robocore/robowrapper.dart';

class RoboTelegram extends RoboWrapper {
  RoboTelegram(Robocore bot) : super(bot);

  Future<dynamic> getChannelOrChat(int id) async {
    return await bot.getTelegramChat(id);
  }

  Future<dynamic> deleteMessage(int chat, id) async {
    return bot.teledart.telegram.deleteMessage(chat, id);
  }

  Future<dynamic> editMessage(int chatId, int id, dynamic content,
      {bool disablePreview = true, bool markdown = true}) async {
    return bot.teledart.telegram.editMessageText(content,
        chat_id: chatId,
        message_id: id,
        parse_mode: (markdown ? 'MarkdownV2' : 'HTML'),
        disable_web_page_preview: disablePreview);
  }

  Future<int?> send(int chatId, dynamic content,
      {bool disablePreview = true, bool markdown = true}) async {
    var message = await bot.teledart.telegram.sendMessage(chatId, content,
        parse_mode: (markdown ? 'MarkdownV2' : 'HTML'),
        disable_web_page_preview: disablePreview);
    return message.message_id;
  }

  Future<dynamic> pinMessage(int chat, id) async {
    return bot.teledart.telegram.pinChatMessage(chat, id);
  }
}
