import 'dart:async';
import 'dart:io';

import 'package:cron/cron.dart';
import 'package:logging/logging.dart';
import 'package:nyxx/nyxx.dart';
import 'package:robocore/command.dart';
import 'package:robocore/core.dart';
import 'package:robocore/swap.dart';

Logger log = Logger("Robocore");

/// Discord bot
class Robocore {
  late Nyxx bot;
  bool ready = false;
  ITextChannel? loggingChannel;
  int loggingLevel = 0;

  /// To interact with Ethereum contracts
  late Core core;

  late StreamSubscription subscription;

  ClientUser get self => bot.self;

  /// Commands
  List<Command> commands = [];

  // Keeping track of some state, queried every minute
  late num rewardsInCORE, rewardsInUSD;

  num lastPriceCOREinUSD = 0;

  late num priceETHinUSD,
      priceETHinCORE,
      priceCOREinETH,
      priceCOREinUSD,
      poolCORE,
      poolETH,
      poolK,
      poolETHinUSD,
      poolCOREinUSD,
      priceLPinUSD,
      priceLPinETH,
      floorCOREinUSD,
      floorCOREinETH,
      floorLPinUSD,
      floorLPinETH,
      floorLiquidity,
      supplyLP;

  // Just testing stuff
  test() async {
    await core.readContracts();
    await updatePriceInfo();
    print(supplyLP);
  }

  /// Run contract queries
  query() async {
    await updatePriceInfo();
    rewardsInCORE = raw18(await core.cumulativeRewardsSinceStart());
    rewardsInUSD = rewardsInCORE * priceETHinUSD;
  }

  /// Call getReserves on both CORE-ETH and ETH-USDT pairs on Uniswap
  /// and update calculations of prices and pooled tokens.
  updatePriceInfo() async {
    var reserves = await core.getReservesCORE2ETH();
    poolCORE = raw18(reserves[0]);
    poolETH = raw18(reserves[1]);
    poolK = poolCORE * poolETH;
    reserves = await core.getReservesETH2USDT();
    // Base is ETH price in USD
    priceETHinUSD = raw6(reserves[1]) / raw18(reserves[0]);
    priceETHinCORE = poolCORE / poolETH;
    // Price of CORE
    priceCOREinETH = poolETH / poolCORE;
    priceCOREinUSD = priceCOREinETH * priceETHinUSD;
    // Pool values
    poolCOREinUSD = poolCORE * priceCOREinUSD;
    poolETHinUSD = poolETH * priceETHinUSD;

    // This is all LPs minted so far
    supplyLP = raw18(await core.totalSupplyCORE2ETH());
    // Price of LP is calculated as the full pool valuated in ETH, divided by supply
    priceLPinETH = ((poolCORE * priceCOREinETH) + poolETH) / supplyLP;
    priceLPinUSD = priceLPinETH * priceETHinUSD;

    // Floor calculations
    // Then k needs to be preserved so if we sell all outsideCORE into the pool
    // then new poolETH needs to be this (all 10000 CORE now in pool) in order
    // to make sure poolK stays the same.
    var newPoolETH = poolK / 10000;
    // This then gives us a new price - the so called floor price
    floorCOREinETH = newPoolETH / 10000;
    floorCOREinUSD = floorCOREinETH * priceETHinUSD;
    // The liquidity is simply twice newPoolETH
    floorLiquidity = newPoolETH * 2;
    // And then we can also calculate floor of LP
    floorLPinETH = floorLiquidity / supplyLP;
    floorLPinUSD = floorLPinETH * priceETHinUSD;
  }

  EmbedBuilder? priceAlert() {
    const limit = 100;
    // Did we move more than limit USD per CORE?
    if (lastPriceCOREinUSD != 0) {
      num diff = lastPriceCOREinUSD - priceCOREinUSD;
      String arrow = diff.isNegative ? "UP" : "DOWN";
      if (diff.abs() > limit) {
        // Let's remember this
        lastPriceCOREinUSD = priceCOREinUSD;
        final embed = EmbedBuilder()
          ..addAuthor((author) {
            author.name = "Price alert! Moved $arrow \$${dec0(diff.abs())}!";
          })
          ..addField(name: "Price CORE", content: priceStringCORE())
          ..addField(name: "Price ETH", content: priceStringETH())
          ..addField(name: "Price LP", content: priceStringLP());
        return embed;
      }
    } else {
      lastPriceCOREinUSD = priceCOREinUSD;
    }
    return null;
  }

  String priceStringCORE([num amount = 1]) {
    return "$amount CORE = ${usd2(priceCOREinUSD * amount)} (${dec4(priceCOREinETH * amount)} ETH)";
  }

  String priceStringLP([num amount = 1]) {
    return "$amount LP = ${usd2(priceLPinUSD * amount)} (${dec4(priceLPinETH * amount)} ETH)";
  }

  String priceStringETH([num amount = 1]) {
    return "$amount ETH = ${usd2(priceETHinUSD * amount)} (${dec4(priceETHinCORE * amount)} ETH)";
  }

  updateUsername() async {
    if (ready) {
      try {
        print("Getting guild");
        var guild = await bot.getGuild(Snowflake("759889689409749052"));
        print("Got guild! $guild");
        guild.changeSelfNick("RoboCORE ${usd0(priceCOREinUSD)}");
      } catch (e) {
        print(e);
      }
    }
  }

  buildCommands() {
    commands
      ..add(
          MentionCommand("@RoboCORE", "", "I will ... say something!", [], []))
      ..add(HelpCommand("help", "h", "Show all commands of RoboCORE", [], []))
      ..add(FAQCommand("faq", "", "Show links to FAQ etc", [], []))
      ..add(StatsCommand(
          "stats",
          "s",
          "Show some basic statistics about CORE, refreshed every minute",
          [],
          []))
      ..add(
          ContractsCommand("contracts", "c", "Show links to contracts", [], []))
      ..add(LogCommand(
          "log",
          "l",
          "Log txns in this channel. \"!l 0\" sets logging level to 0. Level 0=off, 1=whales, 3=swaps",
          [],
          []))
      ..add(PriceCommand(
          "price",
          "p",
          "Show prices, straight from Ethereum. \"!p core\" shows only CORE price (or LP, ETH), and you can also use amount like \"!p 10 core\".",
          [],
          []))
      ..add(FloorCommand("floor", "f",
          "Show current floor prices, straight from Ethereum.", [], []));
  }

  checkLoggingAlert(Swap swap) {
    if (loggingLevel >= 3) {
      var msg = swap.makeMessage();
      loggingChannel?.send(content: msg);
    }
    if (loggingLevel > 0) {
      var whaleAlert = swap.whaleAlert();
      if (whaleAlert != null) {
        loggingChannel?.send(content: whaleAlert);
      }
    }
    if (loggingLevel > 1) {
      var alert = priceAlert();
      if (alert != null) {
        loggingChannel?.send(embed: alert);
      }
    }
  }

  openDatabase() {}

  start() async {
    openDatabase();
    var token = await File('bot-token.txt').readAsString();
    String wsUrl = await File('bot-wsurl.txt').readAsString();
    String apiUrl = await File('bot-apiurl.txt').readAsString();

    bot = Nyxx(token);
    core = Core.randomKey(apiUrl, wsUrl);
    await core.readContracts();

    buildCommands();

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

    // We listen to all Swaps on COREETH
    subscription = core.listenToEvent(core.CORE2ETH, 'Swap', (ev, event) {
      print("Topics: ${event.topics} data: ${event.data}");
      var swap = Swap.from(ev, event);
      swap.save();
      updatePriceInfo();
      checkLoggingAlert(swap);
    });

    // Hook up to Discord messages
    bot.onReady.listen((ReadyEvent e) async {
      log.info("Robocore ready!");
      ready = true;
    });

    bot.onMessageReceived.listen((MessageReceivedEvent e) async {
      for (var cmd in commands) {
        if (await cmd.exec(e, this)) {
          return;
        }
      }
    });
  }

  String buildHelp(ITextChannel channel) {
    var sb = StringBuffer();
    for (var cmd in commands) {
      if (cmd.availableIn(channel.id.toString())) {
        sb.writeln(cmd.helpLine());
      }
    }
    return sb.toString();
  }
}
