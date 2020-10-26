import 'package:nyxx/nyxx.dart';
import 'package:robocore/chat/robodiscordmessage.dart';
import 'package:robocore/chat/robomessage.dart';
import 'package:robocore/commands/command.dart';

class FAQCommand extends Command {
  FAQCommand() : super("faq", "", "faq", "Show links to FAQ etc.");

  @override
  handleMessage(RoboMessage bot) async {
    dynamic answer;
    if (bot is RoboDiscordMessage) {
      answer = EmbedBuilder()
        ..addAuthor((author) {
          author.name = "Various links to good info";
        })
        ..addField(name: "Help", content: "https://help.cvault.finance")
        ..addField(
            name: "Links",
            content:
                "[Twitter](https://twitter.com/CORE_Vault) [Medium](https://medium.com/core-vault) [Telegram](https://t.me/COREVault) [Github](https://github.com/cVault-finance)")
        ..addField(
            name: "Articles",
            content:
                "[Vision](https://medium.com/@0xdec4f/the-idea-project-and-vision-of-core-vault-52f5eddfbfb)")
        ..addFooter((footer) {
          footer.text = "Keep HODLING";
        })
        ..color = bot.color();
    } else {
      answer = """
*Help*
[Help](https://help.cvault.finance)
*Links*
[Twitter](https://twitter.com/CORE_Vault) [Medium](https://medium.com/core-vault) [Telegram](https://t.me/COREVault) [Github](https://github.com/cVault-finance)
*Articles*
[Vision](https://medium.com/@0xdec4f/the-idea-project-and-vision-of-core-vault-52f5eddfbfb)
""";
    }
    return bot.reply(answer, markdown: true);
  }
}
