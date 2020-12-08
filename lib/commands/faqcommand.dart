import 'package:mustache/mustache.dart';
import 'package:robocore/chat/robomessage.dart';
import 'package:robocore/commands/command.dart';
import 'package:robocore/robocore.dart';

class FAQCommand extends Command {
  FAQCommand()
      : super("faq", "f", "faq|f [topic]",
            "Show list of FAQ topics or show the specified named topic");

  static Map faq = {
    "core": {
      "name": "CORE",
      "description":
          "CORE is a token used for the CORE project. You can trade CORE on Uniswap in the [CORE-ETH](https://info.uniswap.org/pair/0x32ce7e48debdccbfe0cd037cc89526e4382cb81b) pair and the [CORE-CBTC](https://info.uniswap.org/pair/0x6fad7d44640c5cd0120deec0301e8cf850becb68) pair. Supply is **fixed** at 10000 CORE, and all CORE are distributed. CORE is not locked in any way, you are free to buy, hodl and sell CORE. Every trade carries a 1% fee."
    },
    "lp": {
      "name": "Liquidity Pool token",
      "description":
          "An LP token, or an LP for short, is a \"receipt\" token that you have added liquidity to either the CORE-ETH or the CORE-CBTC pair. You **can not** convert an LP token back to its underlying assets. But you can stake them on [cvault\.finance](https://cvault.finance) to farm rewards in CORE, or sell/buy them on balancer. CORE-ETH LP tokens are sometimes referred to as lp1. CORE-CBTC tokens, sometimes referred to as lp2, are measured in cmLPs which means centimilli LPs (5 decimal places)."
    },
    "balancer": {
      "name": "Balancer exchange",
      "description":
          "On [Balancer](https://balancer.exchange) you can trade CORE LP tokens. The price of LP tokens on balancer are driven by supply and demand and can be cheaper than minting/zapping your own LP tokens at [cvault.finance](https://cvault.finance). If you use the price command you can see both balancer price and value (minting price). Here is link to [trade CORE-ETH LP tokens](https://balancer.exchange/#/swap/0x32ce7e48debdccbfe0cd037cc89526e4382cb81b/ether) and [to trade CORE-CBTC LP tokens](https://balancer.exchange/#/swap/0x6fad7d44640c5cd0120deec0301e8cf850becb68/ether)."
    },
    "official": {
      "name": "Official links",
      "description":
          "The main website is [cvault.finance](https://cvault.finance) with a [help section](https://help.cvault.finance) and the primary feed for news is on [Twitter](https://twitter.com/CORE_Vault). Articles are published regularly from the team on [Medium](https://medium.com/core-vault). The community is active on both [Telegram](https://t.me/COREVault) and [Discord](https://discord.gg/hPUm9Jh) and code is found on [Github](https://github.com/cVault-finance)."
    },
    "links": {
      "name": "Additional links",
      "description": """
[Core Farming](https://www.corefarming.info)
[Core Charts](https://corecharts.info)
[RoboCORE github](https://github.com/gokr/robocore)
"""
    },
    "audit": {
      "name": "Audits by Arcadia group",
      "description":
          "CORE has been audited by Arcadia and is [available here](https://arcadiamgroup.com/audits/CoreFinal.pdf) and there is also the [audit for ERC95](https://arcadiamgroup.com/audits/ERC95.pdf)."
    },
    "stats": {
      "name": "Statistics around CORE and farming",
      "description":
          "Both [Core Farming](https://www.corefarming.info) and [Core Charts](https://corecharts.info) have useful information. You can also try */stats* command with RoboCORE."
    },
    "etherscan": {
      "name": "Etherscan",
      "description":
          """[CORE vault on Etherscan](https://etherscan.io/address/0xc5cacb708425961594b63ec171f4df27a9c0d8c9)
[CORE token on Etherscan](https://etherscan.io/address/0x62359ed7505efc61ff1d56fef82158ccaffa23d7)
[CBTC token on Etherscan](https://etherscan.io/address/0x7b5982dcab054c377517759d0d2a3a5d02615ab8)
[CORE-ETH pair on Etherscan](https://etherscan.io/address/0x32ce7e48debdccbfe0cd037cc89526e4382cb81b)
[CORE-CBTC pair on Etherscan](https://etherscan.io/address/0x6fad7d44640c5cd0120deec0301e8cf850becb68)
[CORE-FANNY pair on Etherscan](https://etherscan.io/address/0x85d9DCCe9Ea06C2621795889Be650A8c3Ad844BB)
"""
    },
    "uniswap": {
      "name": "Uniswap",
      "description":
          """[Buy CORE on Uniswap](https://app.uniswap.org/#/swap?inputCurrency=0x62359ed7505efc61ff1d56fef82158ccaffa23d7&outputCurrency=ETH)
[CORE token on Uniswap](https://uniswap.info/token/0x62359ed7505efc61ff1d56fef82158ccaffa23d7)
[CBTC token on Uniswap](https://info.uniswap.org/token/0x7b5982dcab054c377517759d0d2a3a5d02615ab8)
[CORE-ETH pair on Uniswap](https://uniswap.info/pair/0x32ce7e48debdccbfe0cd037cc89526e4382cb81b)
[CORE-CBTC pair on Uniswap](https://uniswap.info/pair/0x6fad7d44640c5cd0120deec0301e8cf850becb68)
[CORE-FANNY pair on Uniswap](https://uniswap.info/pair/0x85d9DCCe9Ea06C2621795889Be650A8c3Ad844BB)
"""
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
    },
    "slippage": {
      "name": "Why can't I trade CORE on uniswap?",
      "description": """
You must raise the slippage of the trade to account for the FoT (Fee on Transfer) as well as any real slippage. Current FoT is {{fot}}%.
When the fee is the normal 1%, unless your trade is large you will not have to change the setting.
      """
    },
    "circuit": {
      "name": "Circuit Breaker",
      "description": """
A mechanism employed for the first time in the run up to and including the LG3 event period. This mechanism dynamically raises the FoT and is intended to prevent price gaming and capital extraction that happened on the run up to and beginning of the LGE2 event. Currently FoT is {{fot}}%.
      """
    },
    "fot": {
      "name": "Fee on Transfer (FoT)",
      "description": """
A unique feature of the CORE ecosystem. This adjustable fee is used to determine the percentage of transfer and sell volume (not buy) that is paid back to the LP holders. It is currently {{fot}}%.
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
        ..addField(section['name'], await merge(section['description'], w.bot))
        ..finish();
      return await w.reply(w.answer);
    } else {
      return await w.reply("Use $syntax");
    }
  }

  Future<String> merge(String description, Robocore bot) async {
    var temp = Template(description,
        name: 'test', lenient: false, htmlEscapeValues: false);
    return temp.renderString({'fot': await bot.getFot()});
  }
}
