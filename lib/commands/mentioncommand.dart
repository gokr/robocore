import 'package:robocore/chat/robomessage.dart';
import 'package:robocore/commands/command.dart';
import 'package:robocore/util.dart';

class MentionCommand extends Command {
  MentionCommand()
      : super("@RoboCORE", "", "@RoboCORE", "I will ... say something!");

  // I am valid if the message mentions me
  bool isValid(RoboMessage bot) {
    return bot.isMention();
  }

  static const replies = [
    "Who, me? I am good! 😄",
    "Well, thank you! 😊",
    "You are crazy man, just crazy 🤣",
    "Frankly, my dear, I don't give a damn! 🐸",
    "Just keep swimming 🐟",
    "My name is CORE. Robo CORE. 🤖",
    "Run you fools. Run! 😱",
    "Even the smallest bot can change the course of the future.",
    "It's always darkest just before it goes pitch black"
  ];
  static const wittys = {
    "pump": ["Yeah! ⛽️ it up!"],
    "moon": ["Why not Mars!?"],
    "stupid": ["Who are you calling stupid?"],
    "love": ["I love you too! ❤️"],
    "lambo": ["Anything over my old Golf", "A  DeTomaso Pantera is way cooler"]
  };

  @override
  handleMessage(RoboMessage bot) async {
    // Fallback
    var reply = replies.pickRandom();
    // Try be a tad smarter
    wittys.forEach((k, v) {
      if (bot.textLowerCase.contains(k)) {
        reply = v.pickRandom();
      }
    });
    await bot.reply(reply);
  }

  @override
  String get command => " @RoboCORE";
}
