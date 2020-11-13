import 'package:robocore/chat/robomessage.dart';
import 'package:robocore/commands/command.dart';
import 'package:markdown/markdown.dart';

class FAQCommand extends Command {
  FAQCommand()
      : super("faq", "f", "faq|f [topic]",
            "Show list of FAQ topics or show the specified named topic");

  static Map faq = {
    "core": {
      "name": "CORE",
      "description":
          "CORE is an ERC20 currency token used for the CORE project\\. You can trade CORE on Uniswap in the [CORE\\-ETH](https://info.uniswap.org/pair/0x32ce7e48debdccbfe0cd037cc89526e4382cb81b) pair and the [CORE\\-CBTC](https://info.uniswap.org/pair/0x6fad7d44640c5cd0120deec0301e8cf850becb68) pair\\. Supply is **fixed** at 10000 CORE, and all CORE are distributed\\. CORE is not locked in any way, you are free to buy, hodl and sell CORE like any currency\\. Every trade carries a 1% fee\\."
    },
    "lp": {"name": "Liquidity Pool token", "description": "..."},
    "balancer": {
      "name": "Balancer exchange",
      "description":
          "On [Balancer](https://balancer.exchange) you can trade CORE LP tokens\\. The price of LP tokens on balancer are driven by supply and demand and **can be cheaper** than minting/zapping your own LP tokens at [cvault\\.finance](https://cvault.finance)\\. If you use the price command you can see both balancer price and value \\(minting price\\)\\. Here is link to [trade CORE\\-ETH LP tokens](https://balancer.exchange/#/swap/0x32ce7e48debdccbfe0cd037cc89526e4382cb81b/ether) and [to trade CORE\\-CBTC LP tokens](https://balancer.exchange/#/swap/0x6fad7d44640c5cd0120deec0301e8cf850becb68/ether)\\."
    },
    "official": {
      "name": "Official links",
      "description":
          "The main website is [cvault\\.finance](https://cvault.finance) with a [help section](https://help.cvault.finance) and the primary feed for news is on [Twitter](https://twitter.com/CORE_Vault)\\. Articles are published regularly from the team on [Medium](https://medium.com/core-vault)\\. The community is active on both [Telegram](https://t.me/COREVault) and [Discord](https://discord.gg/hPUm9Jh) and code is found on [Github](https://github.com/cVault-finance)\\."
    },
    "links": {
      "name": "Additional links",
      "description": """
[RoboCORE github](RoboCORE: https://github.com/gokr/robocore)
"""
    },
    "audit": {
      "name": "Audits by Arcadia group",
      "description":
          "CORE has been audited by Arcadia and is [available here](https://arcadiamgroup.com/audits/CoreFinal.pdf)\\."
    },
    "stats": {
      "name": "Statistics around CORE and farming",
      "description":
          "Both [Core Farming](https://www.corefarming.info) and [Core Charts](https://corecharts.info) have useful information\\. You can also try */stats* command with RoboCORE\\."
    },
    "contracts": {
      "name": "Contracts in CORE",
      "description":
          """[Buy CORE on Uniswap](https://app.uniswap.org/#/swap?inputCurrency=0x62359ed7505efc61ff1d56fef82158ccaffa23d7&outputCurrency=ETH)
[CORE vault on Etherscan](https://etherscan.io/address/0xc5cacb708425961594b63ec171f4df27a9c0d8c9)
[CORE token on Uniswap](https://uniswap.info/token/0x62359ed7505efc61ff1d56fef82158ccaffa23d7)
[CORE token on Etherscan](https://etherscan.io/address/0x62359ed7505efc61ff1d56fef82158ccaffa23d7)
[CBTC token on Uniswap](https://info.uniswap.org/token/0x7b5982dcab054c377517759d0d2a3a5d02615ab8)
[CBTC token on Etherscan](https://etherscan.io/address/0x7b5982dcab054c377517759d0d2a3a5d02615ab8)
[CORE\\-ETH pair on Uniswap](https://uniswap.info/pair/0x32ce7e48debdccbfe0cd037cc89526e4382cb81b)
[CORE\\-ETH pair on Etherscan](https://etherscan.io/address/0x32ce7e48debdccbfe0cd037cc89526e4382cb81b)
[CORE\\-CBTC pair on Uniswap](https://uniswap.info/pair/0x6fad7d44640c5cd0120deec0301e8cf850becb68)
[CORE\\-CBTC pair on Etherscan](https://etherscan.io/address/0x6fad7d44640c5cd0120deec0301e8cf850becb68)"""
    },
    "website": {
      "name": "Website URLs",
      "description": """
[website](https://cvault.finance)
[backup 1](https://gateway.pinata.cloud/ipfs/QmXRez85MNjxRpBNMtTq65CWv5tZE1AgGuAZxevqZ83d5P)
[backup 2, also beta site](https://win95.cvault.finance)"""
    },
    "articles": {
      "name": "Article sources on CORE",
      "description": """
 [CORE on Medium](https://medium.com/@CORE_Vault)
 [0xdec4f on Medium](https://medium.com/@0xdec4f)
 [Göran's articles](http://goran.krampe.se/category/core/)
"""
    },
    "twitter": {
      "name": "CORE people on Twitter",
      "description": """
 [CORE](https://twitter.com/CORE_Vault)
 [0xRevert](https://twitter.com/0xRevert)
 [X3](https://twitter.com/x3devships)
 [0xdec4f](https://twitter.com/0xdec4f)
 [Göran](https://twitter.com/gorankrampe)
"""
    }
  };

  @override
  handleMessage(RoboMessage w) async {
    var parts = w.parts;
    // Only !f or !faq
    if (parts.length == 1) {
      return await w.reply("Available topics are: ${faq.keys.join(',')}");
    }
    if (parts.length == 2) {
      var topic = parts[1];
      if (!faq.containsKey(topic)) {
        return await w.reply(
            "No topic named $topic found, use one of ${faq.keys.join(',')}");
      }
      var section = faq[topic];
      w
        ..addField(section['name'], section['description'])
        ..finish();
      return await w.reply(w.answer, markdown: true);
    } else {
      return await w.reply("Use $syntax");
    }
  }
}
