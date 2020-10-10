import 'dart:async';
import 'dart:io';

import 'package:cron/cron.dart';
import 'package:logging/logging.dart';
import 'package:nyxx/nyxx.dart';
import 'package:robocore/command.dart';
import 'package:robocore/core.dart';
import 'package:robocore/event_logger.dart';
import 'package:robocore/swap.dart';

Logger log = Logger("Robocore");

/// Discord bot
class Robocore {
  late Map config;
  late Nyxx bot;
  bool ready = false;

  // All loggers
  List<EventLogger> loggers = [];

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

  Robocore(this.config);

  // Just testing stuff
  test() async {
    await core.readContracts();
    await updatePriceInfo();
    print(supplyLP);
  }

  addLogger(EventLogger logger) {
    loggers.removeWhere((element) =>
        element.channel == logger.channel && element.name == logger.name);
    loggers.add(logger);
  }

  removeLogger(String name, ITextChannel ch) {
    loggers.removeWhere(
        (element) => element.channel == ch && element.name == name);
  }

  removeLoggers(ITextChannel ch) {
    loggers.removeWhere((element) => element.channel == ch);
  }

  loggersFor(ITextChannel ch) {
    return loggers.where((element) => element.channel == ch).toList();
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

  String priceStringCORE([num amount = 1]) {
    return "$amount CORE = ${usd2(priceCOREinUSD * amount)} (${dec4(priceCOREinETH * amount)} ETH)";
  }

  String priceStringLP([num amount = 1]) {
    return "$amount LP = ${usd2(priceLPinUSD * amount)} (${dec4(priceLPinETH * amount)} ETH)";
  }

  String priceStringETH([num amount = 1]) {
    return "$amount ETH = ${usd2(priceETHinUSD * amount)} (${dec4(priceETHinCORE * amount)} CORE)";
  }

  updateUsername() async {
    if (ready) {
      await bot.self.edit(username: "RoboCORE", avatar: File("www/robo.png"));
      /*try {
        print("Getting guild");
        var guild = await bot.getGuild(Snowflake("759889689409749052"));
        print("Got guild! $guild");
        guild.changeSelfNick("RoboCORE ${usd0(priceCOREinUSD)}");
      } catch (e) {
        print(e);
      }*/
    }
  }

  buildCommands() {
    commands
      ..add(MentionCommand(
          "@RoboCORE", "", "@RoboCORE", "I will ... say something!"))
      ..add(HelpCommand(
          "help", "h", "help", "`help|h`\nShow all commands of RoboCORE."))
      ..add(FAQCommand("faq", "", "faq", "`faq`\nShow links to FAQ etc."))
      ..add(StatsCommand("stats", "s", "stats",
          "`stats|s`\nShow some basic statistics about CORE, refreshed every minute."))
      ..add(ContractsCommand("contracts", "c", "contracts",
          "`contracts|c`\nShow links to contracts."))
      ..add(LogCommand("log", "l", "log",
          "`l|log [add|remove] [all|price|whale|swap]`\nControl logging of events in this channel. Note that this is per channel. Only \"log\" will show active loggers."))
      ..add(PriceCommand("price", "p", "price",
          "`price|p [[<amount>] eth|core|lp]`\nShow prices, straight from Ethereum. \"!p core\" shows only price for CORE. You can also use amount like \"!p 10 core\"."))
      ..add(FloorCommand("floor", "f", "floor",
          "`floor|f`\nShow current floor prices, straight from Ethereum."));
  }

  /// Go through all loggers and log
  performLogging(Swap swap) {
    for (var logger in loggers) {
      logger.log(this, swap);
    }
  }

  openDatabase() {}

  start() async {
    openDatabase();

    bot = Nyxx(config['nyxx']);
    core = Core.randomKey(config['apiurl'], config['wsurl']);
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
      //print("Topics: ${event.topics} data: ${event.data}");
      var swap = Swap.from(ev, event);
      swap.save();
      updatePriceInfo();
      performLogging(swap);
    });

    // Hook up to Discord messages
    bot.onReady.listen((ReadyEvent e) async {
      log.info("Robocore ready!");
      ready = true;
      await updateUsername();
    });

    bot.onMessageReceived.listen((MessageReceivedEvent e) async {
      for (var cmd in commands) {
        if (await cmd.exec(e, this)) {
          return;
        }
      }
    });
  }

  EmbedBuilder buildHelp(ITextChannel channel) {
    final embed = EmbedBuilder()
      ..addAuthor((author) {
        author
          ..name = "RoboCORE"
          ..iconUrl = bot.self.avatarURL();
      });
    for (var cmd in commands) {
      if (cmd.availableIn(channel.id.toString())) {
        embed.addField(name: cmd.syntax, content: cmd.help);
      }
    }
    return embed;
  }
}
