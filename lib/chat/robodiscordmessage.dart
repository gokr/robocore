import 'package:nyxx/nyxx.dart';
import 'package:robocore/chat/discordchannel.dart';
import 'package:robocore/chat/robochannel.dart';
import 'package:robocore/chat/robomessage.dart';
import 'package:robocore/chat/robouser.dart';
import 'package:robocore/chat/robodiscord.dart';
import 'package:robocore/robocore.dart';

const discordPrefix = "!";

class RoboDiscordMessage extends RoboDiscord with RoboMessage {
  MessageReceivedEvent e;
  late String text, textLowerCase;
  late List<String> parts;

  RoboDiscordMessage(Robocore bot, this.e) : super(bot) {
    text = e.message.content;
    textLowerCase = text.toLowerCase();
    parts = splitMessage(text);
  }

  String get prefix => discordPrefix;
/*
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
    return (text.startsWith(discordPrefix + cmd.name) ||
        (cmd.short != "" && (text == discordPrefix + cmd.short) ||
            text.startsWith(discordPrefix + cmd.short + " ")));
  }
*/
  String get username => e.message.author.username;
  RoboUser get roboUser => RoboUser.discord(e.message.author.id.id);
  RoboChannel get roboChannel => DiscordChannel(e.message.channelId.id);
  bool get isDirectChat => e.message.channel.type == ChannelType.dm;

  reply(dynamic answer,
      {bool disablePreview = true, bool markdown = false}) async {
    return channelSend(e.message.channel, answer);
  }

  EmbedBuilder buildHelp() {
    final embed = EmbedBuilder()
      ..addAuthor((author) {
        author
          ..name = "RoboCORE"
          ..iconUrl = bot.nyxx.self.avatarURL();
      });
    for (var cmd in bot.commands) {
      embed.addField(name: cmd.syntax, content: cmd.help);
    }
    return embed;
  }

  DiscordColor color() {
    return (e.message.author is CacheMember)
        ? (e.message.author as CacheMember).color
        : DiscordColor.black;
  }

  bool isMention() => e.message.mentions.contains(bot.self);
}
