import 'dart:async';

import 'package:cron/cron.dart';
import 'package:logging/logging.dart';
import 'package:nyxx/nyxx.dart';
import 'package:robocore/command.dart';
import 'package:robocore/core.dart';
import 'package:robocore/event_logger.dart';
import 'package:robocore/model/swap.dart';
import 'package:teledart/model.dart';
import 'package:teledart/teledart.dart';
import 'package:teledart/telegram.dart';

import 'database.dart';

Logger log = Logger("Robocore");

/// Discord bot
class Robocore {
  late Map config;
  late Nyxx discord;
  bool discordReady = false;
  late TeleDart teledart;
  bool teledartReady = false;

  // All loggers
  List<EventLogger> loggers = [];

  /// To interact with Ethereum contracts
  late Core core;

  late StreamSubscription subscription;

  ClientUser get self => discord.self;

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
    rewardsInUSD = rewardsInCORE * priceCOREinUSD;
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
    // to make sure poolK stays the same. However, to be precise we take special
    // care of the 0.3 % Uniswap fee since that goes to pool, increasing liquidity,
    // and should not be included in the k-balancing formula.

    // This was without taking Uniswap fee into account:
    //var newPoolETH = poolK / 10000;
    // 0.3% (the Uniswap fee) of the outsideCORE is not included in balancing k.
    var newPoolETH = poolK / (poolCORE + (10000 - poolCORE) * 0.997);
    // This then gives us a new price - the so called floor price!
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
    /*if (ready) {
      await discord.self
          .edit(username: "RoboCORE", avatar: File("www/robo.png"));
      try {
        print("Getting guild");
        var guild = await bot.getGuild(Snowflake("759889689409749052"));
        print("Got guild! $guild");
        guild.changeSelfNick("RoboCORE ${usd0(priceCOREinUSD)}");
      } catch (e) {
        print(e);
      }
    }
  */
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
      ..add(
          LogCommand("log", "l", "log", "`l|log [add|remove] [all|price|whale|swap]`\nControl logging of events in this channel. Note that this is per channel. Only \"log\" will show active loggers.")
            ..whitelist = [
              759890072392302592,
              764120413507813417,
              763138788297408552
            ]) // price-discussion, robocore, robocore-development
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

  start() async {
    await openDatabase(config);
    log.info("Postgres opened: ${db.databaseName}");

    //await Swap.dropTable();
    //print("dropped");
    //await Swap.createTable();
    //print("created");

    // Create our two bots
    discord = Nyxx(config['nyxx']);
    teledart = TeleDart(Telegram(config['teledart']), Event());

    // Create our interface with Ethereum
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
      updatePriceInfo();
      performLogging(swap);
    });

    // Hook up to Discord messages
    discord.onReady.listen((ReadyEvent e) async {
      log.info("Robocore in Discord is ready!");
      discordReady = true;
      await updateUsername();
    });

    discord.onMessageReceived.listen((MessageReceivedEvent event) async {
      for (var cmd in commands) {
        if (await cmd.execDiscord(event, this)) {
          return;
        }
      }
    });

    // Hook up to Telegram messages
    teledart.start().then((me) {
      log.info('RoboCORE in Telegram is ready!');
      teledartReady = true;
    });

    teledart
        .onMessage(entityType: 'bot_command')
        .listen((TeleDartMessage message) async {
      for (var cmd in commands) {
        if (await cmd.execTelegram(message, this)) {
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
          ..iconUrl = discord.self.avatarURL();
      });
    for (var cmd in commands) {
      if (cmd.availableIn(channel.id.toString())) {
        embed.addField(name: cmd.syntax, content: cmd.help);
      }
    }
    return embed;
  }
}
