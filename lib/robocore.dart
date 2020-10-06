import 'dart:io';

import 'package:cron/cron.dart';
import 'package:logging/logging.dart';
import 'package:nyxx/nyxx.dart';
import 'package:robocore/command.dart';
import 'package:robocore/core.dart';

Logger log = Logger("Robocore");

/// Discord bot
class Robocore {
  late Nyxx bot;

  /// To interact with Ethereum contracts
  late Core core;

  ClientUser get self => bot.self;

  /// Commands
  List<Command> commands = [];

  // Keeping track of some state, queried every minute
  late num rewardsInCORE, rewardsInUSD;

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
    core = Core.randomKey();
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
    //print("poolK: $poolK, poolETH: $poolETH, newPoolETH: $newPoolETH");
    // This then gives us a new price - the so called floor price
    floorCOREinETH = newPoolETH / 10000;
    floorCOREinUSD = floorCOREinETH * priceETHinUSD;
    //print("Price: $floorCOREinETH");
    // The liquidity is simply twice newPoolETH
    floorLiquidity = newPoolETH * 2;
    //print("FloorLiquidity: $floorLiquidity");
    // And then we can also calculate floor of LP
    floorLPinETH = floorLiquidity / supplyLP;
    floorLPinUSD = floorLPinETH * priceETHinUSD;
  }

  buildCommands() {
    commands
      ..add(MentionCommand("@RoboCORE", "I will ... say something!", [], []))
      ..add(HelpCommand("help", "Show all features of RoboCORE", [], []))
      ..add(FAQCommand("faq", "Show links to FAQ etc", [], []))
      ..add(StatsCommand(
          "stats",
          "Show some basic statistics about CORE, refreshed every minute",
          [],
          []))
      ..add(ContractsCommand("contracts", "Show links to to contracts", [], []))
      ..add(StatusCommand("status", "Show I am alive", [], []))
      ..add(PriceCommand("price",
          "Show current price information, straight from contracts", [], []));
  }

  start() async {
    var token = await File('bot-token.txt').readAsString();
    bot = Nyxx(token);
    core = Core.randomKey();
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

    bot.onReady.listen((ReadyEvent e) async {
      log.info("Robocore ready!");
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
        sb.writeln(" ${cmd.command} - ${cmd.help}");
      }
    }
    return sb.toString();
  }
}
