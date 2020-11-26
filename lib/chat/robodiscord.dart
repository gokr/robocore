import 'package:nyxx/nyxx.dart';
import 'package:robocore/robocore.dart';
import 'package:robocore/robowrapper.dart';

class RoboDiscord extends RoboWrapper {
  RoboDiscord(Robocore bot) : super(bot);

  Future<dynamic> getChannelOrChat(int id) async {
    return await bot.getDiscordChannel(id);
  }

  Future<dynamic> getMessage(int channel, id) async {
    var ch = await bot.getDiscordChannel(channel);
    return ch.getMessage(Snowflake(id));
  }

  Future<dynamic> deleteMessage(int channel, id) async {
    var message = await getMessage(channel, id);
    message?.delete();
  }

  Future<dynamic> editMessage(int channel, int id, dynamic content) async {
    var message = await getMessage(channel, id);
    if (content is EmbedBuilder) {
      await message.edit(embed: content);
    } else {
      await message.edit(content: content);
    }
  }

  Future<int> send(int channelId, dynamic content,
      {bool disablePreview = true, bool markdown = true}) async {
    var channel = await bot.getDiscordChannel(channelId);
    var message = await channelSend(channel, content);
    return message.id.id;
  }

  Future<dynamic> pinMessage(int channel, id) async {
    var message = await getMessage(channel, id);
    message.pinMessage();
  }

  Future<Message> channelSend(ITextChannel channel, dynamic content) async {
    if (content is EmbedBuilder) {
      return await channel.send(embed: content);
    } else {
      return await channel.send(content: content);
    }
  }
}
