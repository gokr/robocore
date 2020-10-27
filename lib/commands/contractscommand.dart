import 'package:nyxx/nyxx.dart';
import 'package:robocore/chat/robodiscordmessage.dart';
import 'package:robocore/chat/robomessage.dart';
import 'package:robocore/commands/command.dart';

class ContractsCommand extends Command {
  ContractsCommand()
      : super("contracts", "c", "contracts|c",
            "Show links to relevant contracts.");

  @override
  handleMessage(RoboMessage bot) async {
    dynamic answer;
    if (bot is RoboDiscordMessage) {
      answer = EmbedBuilder()
        ..addAuthor((author) {
          author.name = "Links to CORE token and trading pairs";
          //author.iconUrl = e.message.author.avatarURL();
        })
        ..addField(
            name: "CORE token on Uniswap",
            content:
                "https://uniswap.info/token/0x62359ed7505efc61ff1d56fef82158ccaffa23d7")
        ..addField(
            name: "CORE token on Etherscan",
            content:
                "https://etherscan.io/address/0x62359ed7505efc61ff1d56fef82158ccaffa23d7")
        ..addField(
            name: "CORE-ETH pair on Uniswap",
            content:
                "https://uniswap.info/pair/0x32ce7e48debdccbfe0cd037cc89526e4382cb81b")
        ..addField(
            name: "CORE-ETH pair on Etherscan",
            content:
                "https://etherscan.io/address/0x32ce7e48debdccbfe0cd037cc89526e4382cb81b")
        ..addField(
            name: "CORE-CBTC pair on Uniswap",
            content:
                "https://uniswap.info/pair/0x6fad7d44640c5cd0120deec0301e8cf850becb68")
        ..addField(
            name: "CORE-CBTC pair on Etherscan",
            content:
                "https://etherscan.io/address/0x6fad7d44640c5cd0120deec0301e8cf850becb68")
        ..color = bot.color();
    } else {
      answer = """
Links to CORE token and trading pairs
<a href="https://uniswap.info/token/0x62359ed7505efc61ff1d56fef82158ccaffa23d7">CORE token on Uniswap</a>
<a href="https://etherscan.io/address/0x62359ed7505efc61ff1d56fef82158ccaffa23d7">CORE token on Etherscan</a>
<a href="https://uniswap.info/pair/0x32ce7e48debdccbfe0cd037cc89526e4382cb81b">CORE-ETH pair on Uniswap</a>
<a href="https://etherscan.io/address/0x32ce7e48debdccbfe0cd037cc89526e4382cb81b">CORE-ETH pair on Etherscan</a>
<a href="https://uniswap.info/pair/0x6fad7d44640c5cd0120deec0301e8cf850becb68">CORE-CBTC pair on Uniswap</a>
<a href="https://etherscan.io/address/0x6fad7d44640c5cd0120deec0301e8cf850becb68">CORE-CBTC pair on Etherscan</a>
""";
    }
    return await bot.reply(answer);
  }
}
