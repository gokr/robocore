import 'dart:io';
import 'dart:math';

import 'package:cron/cron.dart';
import 'package:logging/logging.dart';
import 'package:nyxx/nyxx.dart';
import 'package:robocore/core.dart';

Logger log = Logger("Robocore");

/// Discord bot
class Robocore {
  late Nyxx bot;
  late ClientUser me;

  // To interact with CORE contracts
  late Core core;

  // Keeping track of some state, queried every minute
  late BigInt rewards;
  late num priceETHinUSD,
      priceETHinCORE,
      priceCOREinETH,
      priceCOREinUSD,
      poolCORE,
      poolETH,
      poolETHinUSD,
      poolCOREinUSD;

  // Just testing stuff
  test() async {
    core = Core.randomKey();
    await core.readContracts();
    // var a = await core.address;
    // print("Address: ${a.hex}");
    // var b = await core.getBalance();
    // print("Balance: ${b.getValueInUnit(EtherUnit.ether)}");
    print(await core.totalLPTokensMinted());
    print(await core.totalETHContributed());
    print(decimal4Formatter
        .format(raw18(await core.cumulativeRewardsSinceStart())));
  }

  /// Run contract queries
  query() async {
    rewards = await core.cumulativeRewardsSinceStart();
  }

  getPriceInfo() async {
    //  var price0 = await core.price0CumulativeLast();
    //  var price1 = await core.price1CumulativeLast();
    var reserves = await core.getReservesCORE2ETH();
    poolCORE = raw18(reserves[0]);
    poolETH = raw18(reserves[1]);
    reserves = await core.getReservesETH2USDT();
    print(reserves);
    priceETHinUSD = raw6(reserves[1]) / raw18(reserves[0]);
    priceETHinCORE = poolCORE / poolETH;
    priceCOREinETH = poolETH / poolCORE;
    priceCOREinUSD = priceCOREinETH * priceETHinUSD;
    poolCOREinUSD = poolCORE * priceCOREinUSD;
    poolETHinUSD = poolETH * priceETHinUSD;
  }

  start() async {
    var token = await File('bot-token.txt').readAsString();
    bot = Nyxx(token);
    core = Core.randomKey();
    await core.readContracts();

    // Run cron
    var cron = Cron();
    // One initial query
    await query();
    log.info("Scheduling CORE queries");
    cron.schedule(new Schedule.parse("*/1 * * * *"), () async {
      log.info('Running queries ...');
      await query();
      log.info('Done queries.');
    });

    bot.onReady.listen((ReadyEvent e) async {
      log.info("Robocore ready!");
    });

    bot.onMessageReceived.listen((MessageReceivedEvent e) async {
      me = bot.self;
      if (e.message.content == "!status") {
        await e.message.channel.send(content: "👍");
      }
      if (e.message.content == "!price") {
        await getPriceInfo();
        // Create embed with author and footer section.
        final embed = EmbedBuilder()
          ..addField(
              name: "Price CORE",
              content:
                  "1 CORE = ${dec4(priceCOREinETH)} ETH, ${usd2(priceCOREinUSD)}")
          ..addField(
              name: "Price ETH",
              content:
                  "1 ETH = ${dec6(priceETHinCORE)} CORE, ${usd2(priceETHinUSD)}")
          ..addField(name: "Pooled CORE", content: "${dec0(poolCORE)} CORE")
          ..addField(
              name: "Pooled ETH",
              content: "${dec0(poolETH)} ETH, ${usd0(poolETHinUSD)}")
          ..color = (e.message.author is CacheMember)
              ? (e.message.author as CacheMember).color
              : DiscordColor.black;
        // Sent an embed to channel where message received was sent
        e.message.channel.send(embed: embed);
      }
      if (e.message.content == "!faq") {
        // Create embed with author and footer section.
        final embed = EmbedBuilder()
          ..addField(
              name: "FAQ", content: "https://help.cvault.finance/faqs/faq")
          ..addAuthor((author) {
            author.name = e.message.author.username;
            author.iconUrl = e.message.author.avatarURL();
          })
          ..addFooter((footer) {
            footer.text = "Keep HODLING";
          })
          ..color = (e.message.author is CacheMember)
              ? (e.message.author as CacheMember).color
              : DiscordColor.black;
        // Sent an embed to channel where message received was sent
        e.message.channel.send(embed: embed);
      }
      if (e.message.content == "!stats") {
        // Create embed with author and footer section.
        final embed = EmbedBuilder()
          ..addField(
              name: "Cumulative rewards",
              content: "${dec4(raw18(rewards))} CORE")
          ..addFooter((footer) {
            footer.text = "Keep HODLING";
          })
          ..color = (e.message.author is CacheMember)
              ? (e.message.author as CacheMember).color
              : DiscordColor.black;
        // Sent an embed to channel where message received was sent
        e.message.channel.send(embed: embed);
      }
      if (e.message.mentions.contains(me)) {
        const replies = [
          "Who, me? I am good! :smile:",
          "Well, thank you! :blush:",
          "You are crazy man, just crazy"
        ];
        var reply = replies[Random().nextInt(replies.length)];
        // Personal messages
        await e.message.channel.send(content: reply);
      }
    });
  }
}
