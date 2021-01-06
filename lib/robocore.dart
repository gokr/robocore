import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:logging/logging.dart';
import 'package:neat_periodic_task/neat_periodic_task.dart';
import 'package:nyxx/nyxx.dart';
import 'package:robocore/blocklytics.dart';
import 'package:robocore/chat/discordchannel.dart';
import 'package:robocore/chat/robochannel.dart';
import 'package:robocore/chat/robodiscord.dart';
import 'package:robocore/chat/robodiscordmessage.dart';
import 'package:robocore/chat/robofakemessage.dart';
import 'package:robocore/chat/robotelegram.dart';
import 'package:robocore/chat/robotelegrammessage.dart';
import 'package:robocore/commands/fakecommand.dart';
import 'package:robocore/commands/impostordetector.dart';
import 'package:robocore/model/contribution.dart';
import 'package:robocore/model/corebought.dart';
import 'package:robocore/model/robouser.dart';
import 'package:robocore/chat/telegramchannel.dart';
import 'package:robocore/commands/admincommand.dart';
import 'package:robocore/commands/command.dart';
import 'package:robocore/commands/faqcommand.dart';
import 'package:robocore/commands/helpcommand.dart';
import 'package:robocore/commands/idcommand.dart';
import 'package:robocore/commands/lgecommand.dart';
import 'package:robocore/commands/logcommand.dart';
import 'package:robocore/commands/mentioncommand.dart';
import 'package:robocore/commands/paircommand.dart';
import 'package:robocore/commands/postercommand.dart';
import 'package:robocore/commands/pricecommand.dart';
import 'package:robocore/commands/startcommand.dart';
import 'package:robocore/commands/statscommand.dart';
import 'package:robocore/commands/tllcommand.dart';
import 'package:robocore/ethclient.dart';
import 'package:robocore/loggers/eventlogger.dart';
import 'package:robocore/config.dart';
import 'package:robocore/ethereum.dart';
import 'package:robocore/model/swap.dart';
import 'package:robocore/uniswap.dart';
import 'package:robocore/util.dart';
import 'package:robocore/model/poster.dart';
import 'package:teledart/model.dart';
import 'package:teledart/teledart.dart';
import 'package:teledart/telegram.dart';
import 'package:web3dart/web3dart.dart';

import 'package:shelf_router/shelf_router.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

import 'database.dart';

// Super users
var gokr = RoboUser.both("124467899447508992", "1156133961", "gokr", null);
var CryptoXman =
    RoboUser.both("298396371789152258", "1179513113", "CryptoXman", null);
var xRevert =
    RoboUser.both("751362716962390086", "1118664380", "0xRevert", null);
var X3 = RoboUser.both("757109953910538341", "1358048057", "X 3", null);

var officialChat = TelegramChannel(-1001195529102);
var priceAndTradingChat = TelegramChannel(-1001361865863);
var coreLPTradingChat = TelegramChannel(-1001443117633);
var priceDiscussionChannel = DiscordChannel(759890072392302592);
var robocoreChannel = DiscordChannel(764120413507813417);
var robocoreDevelopmentChannel = DiscordChannel(763138788297408552);
var moderatorChannel = DiscordChannel(762398011074412605);

// For tests
var robocoreTestGroup = TelegramChannel(-440184090);
var robocoreTestChannel = DiscordChannel(762629759393726464);
var robocoreTestChannelLogger = DiscordChannel(763910363439431700);

/// The bot
class Robocore {
  late Map config;
  late Nyxx nyxx;
  bool discordReady = false;
  late TeleDart teledart;
  bool teledartReady = false;

  /// Abstraction wrappers
  late RoboDiscord discord;
  late RoboTelegram telegram;

  // All loggers
  List<EventLogger> loggers = [];

  /// To interact with Ethereum contracts
  late EthClient ethClient;

  /// API
  late HttpServer server;

  late StreamSubscription subscription;

  ClientUser get self => nyxx.self;

  /// Commands
  List<Command> commands = [];

  late num priceETHinUSD,
      priceWBTCinETH,
      priceWBTCinUSD,
      COREburned,
      COREsupply,
      floorCOREinUSD,
      floorCOREinETH,
      floorLPinUSD,
      floorLPinETH,
      floorLP2inUSD,
      floorLP2inWBTC,
      floorLPFANNYinUSD,
      floorLPFANNYinFANNY,
      floorLP3inUSD,
      floorLP3inDAI,
      floorLiquidityETH,
      floorLiquidityWBTC,
      floorLiquidityFANNY,
      floorLiquidityDAI,
      TLLinUSD,
      TVPLinUSD;

  late num lge3COREBought,
      lge3COREBoughtInUSD,
      lge3COREBoughtLast24Hours,
      lge3COREBoughtLast24HoursInUSD,
      lge3COREContributed,
      lge3COREContributedInUSD,
      lge3COREContributedLastHour,
      lge3COREContributedLastHourInUSD,
      lge3CORE,
      lge3COREinUSD,
      lge3DAI,
      lge3DAIinUSD,
      lge3WETH,
      lge3WETHinUSD;

  Robocore(this.config);

  // Just testing stuff
  test() async {
    await openDatabase(config);
    log.info("Postgres opened: ${db.databaseName}");

    // Create our interface with Ethereum
    ethClient = EthClient.randomKey(config['apiurl'], config['wsurl']);
    await ethClient.initialize();

    // GraphQL wrappers
    await Blocklytics().connect(config['thegraph']);
    await Uniswap().connect(config['thegraph']);

    // Create our Ethereum world
    await Ethereum(ethClient).initialize();

    // One initial update
    await updatePriceInfo(null);
  }

  bool realRobo() {
    return config['prod'];
  }

  addLogger(EventLogger logger) {
    loggers.removeWhere((element) =>
        element.channel == logger.channel && element.name == logger.name);
    loggers.add(logger);
  }

  removeLogger(String name, RoboChannel ch) {
    loggers.removeWhere(
        (element) => element.channel == ch && element.name == name);
  }

  removeLoggers(RoboChannel ch) {
    loggers.removeWhere((element) => element.channel == ch);
  }

  loggersFor(RoboChannel ch) {
    return loggers.where((element) => element.channel == ch).toList();
  }

  /// Run contract queries
  background() async {
    // Update pair stats
    try {
      await ethereum.fetchStats();
    } catch (e, s) {
      log.warning("Exception during update of pair stats $e, $s", e, s);
    }
    // Update posters
    try {
      var posters = await Poster.getAll();
      for (var p in posters) {
        // Call for both Discord and Telegram
        p.update(discord);
        p.update(telegram);
      }
    } catch (e, s) {
      log.warning("Exception during update of posters", e, s);
    }
  }

  Future<ITextChannel> getDiscordChannel(int id) async {
    return await nyxx.getChannel<ITextChannel>(Snowflake(id.toString()));
  }

  Future<Chat> getTelegramChat(int id) async {
    return await teledart.telegram.getChat(id);
  }

  Future<double> getFot() async {
    final result =
        await ethereum.TRANSFERCHECKER.callFunction('feePercentX100');
    return result.first.toDouble() / 10.0;
  }

  updateLGE3Info() async {
    lge3COREBought = raw18(await CoreBought.getTotalSum(3));
    lge3COREBoughtInUSD = lge3COREBought * priceCOREinUSD;
    lge3COREBoughtLast24Hours =
        raw18(await CoreBought.getSumLast(Duration(hours: 24)));
    lge3COREBoughtLast24HoursInUSD = lge3COREBoughtLast24Hours * priceCOREinUSD;

    lge3COREContributedLastHour =
        raw18(await Contribution.getSumLast(Duration(hours: 1)));
    lge3COREContributedLastHourInUSD =
        lge3COREContributedLastHour * priceCOREinUSD;

    //lge3COREContributed = raw18(await Contribution.getTotalSum(3));
    //lge3COREContributedInUSD = lge3COREContributed * priceCOREinUSD;

    lge3CORE = raw18(await ethereum.CORE.balanceOf(ethereum.LGE3.address));
    lge3COREinUSD = lge3CORE * priceCOREinUSD;
    lge3DAI = raw18(await ethereum.DAI.balanceOf(ethereum.LGE3.address));
    lge3DAIinUSD = lge3DAI * priceDAIinUSD;
    lge3WETH = raw18(await ethereum.WETH.balanceOf(ethereum.LGE3.address));
    lge3WETHinUSD = lge3WETH * priceETHinUSD;
  }

/*
  updateLGE2Info() async {
    //lge2CORE = raw18(await core.lge2TotalCOREContributed());
    //lge2COREinUSD = lge2CORE * priceCOREinUSD;
    //lge2ETH = raw18(await core.lge2TotalETHContributed());
    //lge2ETHinUSD = lge2ETH * priceETHinUSD;
    //lge2WrapToken = raw18(await core.lge2TotalWrapTokenContributed());
    lge2COREBought = raw18(await CoreBought.getTotalSum());
    lge2COREBoughtInUSD = lge2COREBought * priceCOREinUSD;
    lge2COREBoughtLast24Hours =
        raw18(await CoreBought.getSumLast(Duration(hours: 24)));
    lge2COREBoughtLast24HoursInUSD = lge2COREBoughtLast24Hours * priceCOREinUSD;

    lge2ETHContributedLastHour =
        raw18(await Contribution.getSumLast(Duration(hours: 1)));
    lge2ETHContributedLastHourInUSD =
        lge2ETHContributedLastHour * priceCOREinUSD;

    lge2CORE = raw18(
        await ethClient.balanceOf(ethClient.ethClient, ethClient.LGE2Addr));
    lge2COREinUSD = lge2CORE * priceCOREinUSD;
    lge2WBTC =
        raw8(await ethClient.balanceOf(ethClient.wbtc, ethClient.LGE2Addr));
    lge2WBTCinUSD = lge2WBTC * priceWBTCinUSD;
  }
*/

  /// Update base metrics (USD prices), the affected pair and finally floor of CORE.
  updatePriceInfo(Swap? swap) async {
    // First update pairs (or a single pair)
    if (swap != null) {
      swap.pair.update();
    } else {
      await ethereum.updatePairs();
    }
    priceETHinUSD = ethereum.ETH2USDT.price1;
    priceWBTCinETH = ethereum.WBTC2ETH.price1;
    priceWBTCinUSD = priceWBTCinETH * priceETHinUSD;
    await updateFloorPrice();
  }

  // Update floor price of CORE. We now use q-formula.
  updateFloorPrice() async {
    // First we find total supply of CORE: 10000 - burned
    COREburned =
        raw18(await ethereum.CORE.balanceOf(ethereum.COREBURN.address));
    COREsupply = 10000 - COREburned;
    // Then we find all pooled CORE
    var p1 = ethereum.CORE2ETH;
    var p2 = ethereum.CORE2CBTC;
    var p3 = ethereum.CORE2FANNY;
    var p4 = ethereum.COREDAI2WCORE;
    var poolCORE = p1.pool1 + p2.pool1 + p3.pool1 + p4.pool2;
    // And we can find q
    var q = (COREsupply - poolCORE) / poolCORE;
    // Floor for each pair, in the non CORE token
    var f1 = p1.floor2(q);
    var f2 = p2.floor2(q);
    var f3 = p3.floor2(q);
    var f4 = p4.floor1(q);

    // Take average of all floors, in ETH
    floorCOREinETH = (f1 +
            (f2 * priceWBTCinETH) +
            (f3 * priceFANNYinETH) +
            (f4 * priceDAIinETH)) /
        4;
    floorCOREinUSD = floorCOREinETH * priceETHinUSD;

    // And then we can also calculate floor of LPs
    // The liquidity is simply twice newPoolXXX
    var newPoolETH = p1.poolK / (p1.pool1 + (p1.pool1 * q));
    floorLiquidityETH = newPoolETH * 2;
    floorLPinETH = floorLiquidityETH / p1.supplyLP;
    floorLPinUSD = floorLPinETH * priceETHinUSD;

    var newPoolWBTC = p2.poolK / (p2.pool1 + (p2.pool1 * q));
    floorLiquidityWBTC = newPoolWBTC * 2;
    floorLP2inWBTC = floorLiquidityWBTC / p2.supplyLP;
    floorLP2inUSD = floorLP2inWBTC * priceWBTCinUSD;

    var newPoolFANNY = p3.poolK / (p3.pool1 + (p3.pool1 * q));
    floorLiquidityFANNY = newPoolFANNY * 2;
    floorLPFANNYinFANNY = floorLiquidityFANNY / p3.supplyLP;
    floorLPFANNYinUSD = floorLPFANNYinFANNY * priceFANNYinUSD;

    var newPoolDAI = p4.poolK / (p4.pool2 + (p4.pool2 * q));
    floorLiquidityDAI = newPoolDAI * 2;
    floorLP3inDAI = floorLiquidityDAI / p4.supplyLP;
    floorLP3inUSD = floorLP3inDAI * priceDAIinUSD;

    // TLL - Total Liquidity Locked
    TLLinUSD = ethereum.CORE2CBTC.liquidity * priceWBTCinUSD;
    TLLinUSD += ethereum.CORE2ETH.liquidity * priceETHinUSD;
    TLLinUSD += ethereum.CORE2FANNY.liquidity * priceFANNYinUSD;
    TLLinUSD += ethereum.COREDAI2WCORE.liquidity * priceCOREinUSD;
    // TVPL - Total Value Permanently Locked
    TVPLinUSD = floorLiquidityETH * priceETHinUSD;
    TVPLinUSD += floorLiquidityWBTC * priceWBTCinUSD;
    TVPLinUSD += floorLiquidityFANNY * priceFANNYinUSD;
    TVPLinUSD += floorLiquidityDAI * priceDAIinUSD;
  }

  // Shortcuts for readability
  num get priceCOREinETH => ethereum.CORE2ETH.price1;
  num get priceCOREinDAI => ethereum.COREDAI2WCORE.price2;
  num get priceFANNYinCORE => ethereum.CORE2FANNY.price2;
  num get priceCOREinCBTC => ethereum.CORE2CBTC.price1;
  num get priceETHinCORE => ethereum.CORE2ETH.price2;
  num get priceDAIinCORE => ethereum.COREDAI2WCORE.price1;
  num get priceCBTCinCORE => ethereum.CORE2CBTC.price2;
  num get priceCOREinUSD => priceCOREinETH * priceETHinUSD;
  num get priceFANNYinUSD => priceFANNYinCORE * priceCOREinUSD;
  num get priceFANNYinETH => priceFANNYinCORE * priceCOREinETH;
  num get priceDAIinETH => ethereum.DAI2ETH.price1;
  num get priceDAIinUSD => priceDAIinETH * priceETHinUSD;
  num get valueLPinETH => ethereum.CORE2ETH.valueLP;
  num get valueLPinUSD => valueLPinETH * priceETHinUSD;
  num get priceLPinETH => ethereum.CORE2ETH.priceLP;
  num get priceLPinUSD => priceLPinETH * priceETHinUSD;
  num get valueLP2inCBTC => ethereum.CORE2CBTC.valueLP;
  num get valueLP2inUSD => valueLP2inCBTC * priceWBTCinUSD;
  num get priceLP2inETH => ethereum.CORE2CBTC.priceLP;
  num get priceLP2inUSD => priceLP2inETH * priceETHinUSD;
  num get valueLP3inCORE => ethereum.COREDAI2WCORE.valueLP;
  num get valueLP3inUSD => valueLP3inCORE * priceCOREinUSD;
  num get priceLP3inETH => ethereum.COREDAI2WCORE.priceLP;
  num get priceLP3inUSD => priceLP3inETH * priceETHinUSD;

  String priceStringCORE([num amount = 1]) {
    return "$amount CORE = ${usd2(priceCOREinUSD * amount)} (${dec4(priceCOREinETH * amount)} ETH, ${dec4(priceCOREinDAI * amount)} DAI,  ${dec4(priceCOREinCBTC * amount)} CBTC)";
  }

  String priceStringFANNY([num amount = 1]) {
    return "$amount FANNY = ${usd2(priceFANNYinUSD * amount)} (${dec4(priceFANNYinCORE * amount)} CORE)";
  }

  String floorStringCORE([num amount = 1]) {
    return "$amount FLOOR CORE = ${usd2(floorCOREinUSD * amount)} (${dec4(floorCOREinETH * amount)} ETH)";
  }

  String floorStringLP1([num amount = 1]) {
    return "$amount FLOOR LP = ${usd2(floorLPinUSD * amount)} (${dec4(floorLPinETH * amount)} ETH)";
  }

  String floorStringLP2([num amount = 1]) {
    return "$amount FLOOR cmLP = ${usd2(floorLP2inUSD * toCentimilli(amount))} (${dec4(floorLP2inWBTC * toCentimilli(amount))} CBTC)";
  }

  String floorStringLP3([num amount = 1]) {
    return "$amount FLOOR LP3 = ${usd2(floorLP3inUSD * amount)} (${dec4(floorLP3inDAI * amount)} DAI)";
  }

  String priceStringLP1([num amount = 1]) {
    return "$amount LP1 = ${usd2(priceLPinUSD * amount)} (${dec4(priceLPinETH * amount)} ETH)";
  }

  String valueStringLP1([num amount = 1]) {
    return "$amount LP1 = ${usd2(valueLPinUSD * amount)} (${dec4(valueLPinETH * amount)} ETH)";
  }

  String priceStringLP2([num amount = 1]) {
    return "$amount cmLP = ${usd2(priceLP2inUSD * toCentimilli(amount))} (${dec4(priceLP2inETH * toCentimilli(amount))} ETH)";
  }

  String valueStringLP2([num amount = 1]) {
    return "$amount cmLP = ${usd2(valueLP2inUSD * toCentimilli(amount))} (${dec4(valueLP2inCBTC * toCentimilli(amount))} CBTC)";
  }

  String priceStringLP3([num amount = 1]) {
    return "$amount LP3 = ${usd2(priceLP3inUSD * amount)} (${dec4(priceLP3inETH * amount)} ETH)";
  }

  String valueStringLP3([num amount = 1]) {
    return "$amount LP3 = ${usd2(valueLP3inUSD * amount)} (${dec4(valueLP3inCORE * amount)} CORE)";
  }

  String priceStringETH([num amount = 1]) {
    return "$amount ETH = ${usd2(priceETHinUSD * amount)} (${dec4(priceETHinCORE * amount)} CORE)";
  }

  String priceStringDAI([num amount = 1]) {
    return "$amount DAI = ${usd2(priceDAIinUSD * amount)} (${dec6(priceDAIinCORE * amount)} CORE)";
  }

  String priceStringWBTC([num amount = 1]) {
    return "$amount WBTC = ${usd2(priceWBTCinUSD * amount)} (${dec4(priceCBTCinCORE * amount)} CORE)";
  }

  String prices() {
    return """
${priceStringCORE()}
${priceStringFANNY()}
${priceStringETH()}
${priceStringDAI()}
${priceStringWBTC()}""";
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
      ..add(MentionCommand())
      ..add(HelpCommand()..blacklist = [officialChat])
      ..add(FakeCommand()..users = [gokr])
      ..add(ImpostorDetectorCommand()..users = [gokr])
      ..add(FAQCommand())
      ..add(StartCommand()..blacklist = [officialChat])
      ..add(StatsCommand()..blacklist = [officialChat])
      ..add(LGECommand())
      ..add(LogCommand()
        ..validForAllInDM = true
        ..users = [gokr, CryptoXman, xRevert, X3]
        ..whitelist = [
          priceAndTradingChat,
          priceDiscussionChannel,
          robocoreTestGroup,
          robocoreChannel,
          robocoreDevelopmentChannel
        ])
      ..add(PriceCommand()..blacklist = [officialChat])
      ..add(PairCommand()..blacklist = [officialChat])
      ..add(TLLCommand()..blacklist = [officialChat])
      ..add(IdCommand())
      ..add(AdminCommand()..users = [gokr])
      ..add(PosterCommand()..users = [gokr, CryptoXman, xRevert, X3]);
  }

  /// Go through all loggers and let them log if they want to
  performLogging(Swap swap) {
    for (var logger in loggers) {
      try {
        logger.log(this, swap);
      } catch (e) {
        log.warning("Error calling logger: $e");
      }
    }
  }

  createExtensions() async {
    await db.query("CREATE EXTENSION fuzzystrmatch;");
  }

  sendModerators(String message) async {
    await discord.send(moderatorChannel.id, message, markdown: false);
  }

  start() async {
    hierarchicalLoggingEnabled = true;
    await openDatabase(config);
    log.info("Postgres opened: ${db.databaseName}");

    //await createExtensions();

    // Create our two bots
    nyxx = Nyxx(config['nyxx'], useDefaultLogger: false);
    teledart = TeleDart(Telegram(config['teledart']), Event());

    // Create abstraction wrappers
    discord = RoboDiscord(this);
    telegram = RoboTelegram(this);

    // GraphQL wrappers
    await Blocklytics().connect(config['thegraph']);
    await Uniswap().connect(config['thegraph']);

    // Create our interface with Ethereum
    ethClient = EthClient.randomKey(config['apiurl'], config['wsurl']);
    await ethClient.initialize();

    // Create our Ethereum world
    await Ethereum(ethClient).initialize();

    // Add all commands
    buildCommands();

    // Standard setup, if I am real RoboCORE
    if (realRobo()) {
      print("This is prod, performing standard setup");
      for (var cmd in [
        "!l add core-eth price 5",
        "!l add core-cbtc price 5",
        "!l add core-eth whalebuy 10",
        "!l add core-cbtc whalebuy 10"
      ]) {
        RoboFakeMessage(this, cmd, priceAndTradingChat, gokr).runCommands();
      }
      for (var cmd in [
        "!l add core-eth price 5",
        "!l add core-cbtc price 5",
        "!l add core-eth whalebuy 10",
        "!l add core-cbtc whalebuy 10",
        "!l add core-eth whalesell 10",
        "!l add core-cbtc whalesell 10"
      ]) {
        RoboFakeMessage(this, cmd, priceDiscussionChannel, gokr).runCommands();
      }
    } else {
      print("This is NOT prod");
    }

    // One initial update
    await updatePriceInfo(null);

    // We listen to all Swaps on COREETH
    subscription = ethereum.CORE2ETH.listenToEvent('Swap', (ev, event) {
      //print("Topics: ${event.topics} data: ${event.data}");
      try {
        var swap = Swap.from(ev, event, ethereum.CORE2ETH);
        updatePriceInfo(swap);
        performLogging(swap);
      } catch (e) {
        log.warning("Exception during swap handling: ${e.toString()}");
      }
    });

    // We listen to all Swaps on CORE2CBTC
    subscription = ethereum.CORE2CBTC.listenToEvent('Swap', (ev, event) {
      //print("Topics: ${event.topics} data: ${event.data}");
      try {
        var swap = Swap.from(ev, event, ethereum.CORE2CBTC);
        updatePriceInfo(swap);
        performLogging(swap);
      } catch (e) {
        log.warning("Exception during swap handling: ${e.toString()}");
      }
    });

    // We listen to all Swaps on CORE2FANNY
    subscription = ethereum.CORE2FANNY.listenToEvent('Swap', (ev, event) {
      //print("Topics: ${event.topics} data: ${event.data}");
      try {
        var swap = Swap.from(ev, event, ethereum.CORE2FANNY);
        updatePriceInfo(swap);
        performLogging(swap);
      } catch (e) {
        log.warning("Exception during swap handling: ${e.toString()}");
      }
    });

    // We listen to all Swaps on COREDAI2WCORE
    subscription = ethereum.COREDAI2WCORE.listenToEvent('Swap', (ev, event) {
      //print("Topics: ${event.topics} data: ${event.data}");
      try {
        var swap = Swap.from(ev, event, ethereum.COREDAI2WCORE);
        updatePriceInfo(swap);
        performLogging(swap);
      } catch (e) {
        log.warning("Exception during swap handling: ${e.toString()}");
      }
    });

    // We listen to all Contributions on LGE3
    /*subscription =
        ethereum.LGE3.listenToEvent('Contibution', (ev, event) async {
      print("Contibution: ${event.topics} data: ${event.data}");
      var contrib = Contribution.from(3, ev, event);
      await logContribution(contrib);
    });

    // We listen to all WETH Contributions on LGE3 using a special trick
    subscription = ethereum.WETH.listenToEvent('Deposit', (ev, event) async {
      //print("Deposit: ${event.topics} data: ${event.data}");
      // If destination is LGE3, then this is a WETH Contribution to LGE3
      final decoded = ev.decodeResults(event.topics, event.data);
      var dest = decoded[0] as EthereumAddress;
      //print("Dest: $dest");
      if (dest == ethereum.LGE3.address) {
        print("LOGGING ETH");
        var tx = event.transactionHash;
        var rec = await ethClient.web3Client.getTransactionReceipt(tx);
        var sender = rec.from;
        var coreValue = BigInt.from(
            (raw18(decoded[1] as BigInt) / priceCOREinETH) * pow(10, 18));
        var contrib = Contribution.fromWETHDeposit(3, tx, coreValue, sender);
        await logContribution(contrib);
      }
    });

    // We listen to all COREBought on LGE3
    subscription = ethereum.LGE3.listenToEvent('COREBought', (ev, event) async {
      print("COREBought: ${event.topics} data: ${event.data}");
      final decoded = ev.decodeResults(event.topics, event.data);
      var tx = event.transactionHash;
      var rec = await ethClient.web3Client.getTransactionReceipt(tx);
      var sender = rec.from;
      var coreAmt = decoded[0] as BigInt;
      var cb = CoreBought(0, 3, coreAmt, sender, tx);
      await logCoreBought(cb);
    });
*/
    // When we are ready in Discord
    nyxx.onReady.listen((ReadyEvent e) async {
      log.info("Robocore in Discord is ready!");
      discordReady = true;
      await updateUsername();
    });

    // May be interesting
    nyxx.onGuildMemberAdd.listen((GuildMemberAddEvent event) async {
      var member = event.member!;
      print(
          "New member ${member.id} username: ${member.username} tag: ${member.tag} nickname: ${member.nickname}");
      if (member.nickname != null) {
        var matches = await RoboUser.findFuzzyUsers(member.nickname!, 2);
        if (matches.isNotEmpty) {
          await sendModerators(
              "Fuzzy matches ${member.nickname} nickname with: $matches");
        }
      }
      var matches = await RoboUser.findFuzzyUsers(member.username, 2);
      if (matches.isNotEmpty) {
        await sendModerators(
            "Fuzzy matches ${member.username} username with: $matches");
      }
    });

    // May be interesting
    nyxx.onGuildMemberUpdate.listen((GuildMemberUpdateEvent event) async {
      if (event.member is CacheMember) {
        var member = event.member as CacheMember;
        print(
            "CacheMember ${member.id} updated: ${member.tag} nickname: ${member.nickname}");
        var matches = await RoboUser.findFuzzyUsers(
            member.nickname ?? member.username, 2);
        if (matches.isNotEmpty) {
          print(
              "Fuzzy matches ${member.nickname ?? member.username} with: $matches");
        }
      } else {
        print("Member ${event.member?.id} updated: ${event.member?.tag}");
      }
    });

    nyxx.onUserUpdate.listen((UserUpdateEvent event) async {
      await sendModerators(
          "User ${event.user.id} updated: ${event.user.tag} username: ${event.user.username}");
    });

    // All Discord messages
    nyxx.onMessageReceived.listen((MessageReceivedEvent event) async {
      try {
        var msg = RoboDiscordMessage(this, event);
        await msg.resolveUser();
        await msg.runCommands();
      } catch (e) {
        log.warning("Exception during runcommands: ${e.toString()}");
      }
    });

    // When we are ready in Telegram
    teledart.start().then((me) {
      log.info('RoboCORE in Telegram is ready!');
      teledartReady = true;
    });

    // All Telegram bot commands
    teledart
        .onMessage(entityType: 'bot_command')
        .listen((TeleDartMessage message) async {
      try {
        RoboTelegramMessage(this, message).runCommands();
      } catch (e) {
        log.warning("Exception during runcommands: ${e.toString()}");
      }
    });

    // All Telegram messages mentioning me
    teledart
        .onMessage(entityType: 'mention')
        .listen((TeleDartMessage message) async {
      try {
        RoboTelegramMessage(this, message).runCommands();
      } catch (e) {
        log.warning("Exception during runcommands: ${e.toString()}");
      }
    });

    /* NOT YET!
    teledart.onInlineQuery().listen((inlineQuery) async {
      var query = inlineQuery.query;
      print("Query: $query");
      for (var cmd in commands) {
        var result = await cmd.inlineTelegram(query, this);
        if (result != null) {
          inlineQuery.answer([
            InlineQueryResultArticle()
              ..id = cmd.command
              ..title = result
              ..input_message_content = (InputTextMessageContent()
                ..message_text = result
                ..parse_mode = 'HTML')
          ]);
        }
      }
      inlineQuery.answer([
        InlineQueryResultArticle()
          ..id = 'noidea'
          ..title = 'No idea!'
          ..input_message_content = (InputTextMessageContent()
            ..message_text = 'Sorry, did not understand that!'
            ..parse_mode = 'HTML')
      ]);
    });
    */

    startAPI();

    // Base background tasks are run every 10 seconds
    final scheduler = NeatPeriodicTaskScheduler(
      interval: Duration(seconds: 10),
      name: 'background',
      timeout: Duration(seconds: 60),
      task: () async => background(),
      minCycle: Duration(seconds: 5),
    );

    // Force this to be less chatty
    Logger('neat_periodic_task').level = Level.WARNING;
    scheduler.start();
    await ProcessSignal.sigterm.watch().first;
    await scheduler.stop();
  }

  DateTime stamp = DateTime.now();

  String? priceCached, tvplCached;

  bool validCache() {
    return stamp.isAfter(DateTime.now());
  }

  updateCache() async {
    print("Updating API cache");
    await updatePriceInfo(null);
    tvplCached = jsonEncode({
      'TLLinUSD': TLLinUSD,
      'TVPLinUSD': TVPLinUSD,
      'floorCOREinUSD': floorCOREinUSD,
      'floorCOREinETH': floorCOREinETH,
      'floorLPinUSD': floorLPinUSD,
      'floorLPinETH': floorLPinETH,
      'floorLP2inUSD': floorLP2inUSD,
      'floorLP2inWBTC': floorLP2inWBTC,
      'floorLPFANNYinUSD': floorLPFANNYinUSD,
      'floorLPFANNYinFANNY': floorLPFANNYinFANNY,
      'floorLP3inUSD': floorLP3inUSD,
      'floorLP3inDAI': floorLP3inDAI,
      'floorLiquidityETH': floorLiquidityETH,
      'floorLiquidityWBTC': floorLiquidityWBTC,
      'floorLiquidityFANNY': floorLiquidityFANNY,
      'floorLiquidityDAI': floorLiquidityDAI
    });
    priceCached = jsonEncode({
      'priceWBTCinETH': priceWBTCinETH,
      'priceWBTCinUSD': priceWBTCinUSD,
      'priceETHinUSD': priceETHinUSD,
      'priceCOREinETH': priceCOREinETH,
      'priceFANNYinCORE': priceFANNYinCORE,
      'priceCOREinCBTC': priceCOREinCBTC,
      'priceETHinCORE': priceETHinCORE,
      'priceCBTCinCORE': priceCBTCinCORE,
      'priceCOREinUSD': priceCOREinUSD,
      'priceFANNYinUSD': priceFANNYinUSD,
      'priceFANNYinETH': priceFANNYinETH,
      'priceDAIinETH': priceDAIinETH,
      'priceDAIinUSD': priceDAIinUSD,
      'priceDAIinCORE': priceDAIinCORE,
      'valueLPinETH': valueLPinETH,
      'valueLPinUSD': valueLPinUSD,
      'priceLPinETH': priceLPinETH,
      'priceLPinUSD': priceLPinUSD,
      'valueLP2inCBTC': valueLP2inCBTC,
      'valueLP2inUSD': valueLP2inUSD,
      'priceLP2inETH': priceLP2inETH,
      'priceLP2inUSD': priceLP2inUSD,
      'valueLP3inCORE': valueLP3inCORE,
      'valueLP3inUSD': valueLP3inUSD,
      // 'priceLP3inETH': priceLP3inETH,
      // 'priceLP3inUSD': priceLP3inUSD
    });
  }

  startAPI() async {
    var app = Router();

    var headers = {
      HttpHeaders.contentTypeHeader: "application/json",
      "Access-Control-Allow-Origin": "*"
    };

    app.get('/hello', (Request request) {
      return Response.ok('RoboCORE here, hi!');
    });

    app.get('/tvpl', (Request request) async {
      if (!validCache()) {
        stamp = DateTime.now().add(Duration(minutes: 2));
        await updateCache();
      }
      return Response.ok(tvplCached, headers: headers);
    });

    app.get('/price', (Request request) async {
      if (!validCache()) {
        stamp = DateTime.now().add(Duration(minutes: 2));
        await updateCache();
      }
      return Response.ok(priceCached, headers: headers);
    });

    server = await io.serve(app.handler, 'localhost', 10099);
  }

  logContribution(Contribution c) async {
    await updateLGE3Info();
    var core = raw18(c.coreValue);
    var eth = core * priceCOREinETH;
    var limit1kusd = 1000 / priceCOREinUSD;
    print("LOGGING CONTRIB: $core $limit1kusd");
    if (core > limit1kusd) {
      print("OK, more than 1k");
      for (var channel in [
        priceDiscussionChannel,
        priceAndTradingChat,
        officialChat
      ]) {
        //for (var channel in [robocoreTestChannel, robocoreTestGroup]) {
        var wrapper = channel.getWrapperFromBot(this);
        var answer;
        if (wrapper is RoboDiscord) {
          var happies = makeHappies(eth, 190);
          answer = EmbedBuilder()
            ..addField(
                name:
                    "Contribution ${dec4(core)} CORE value (${usd2(priceCOREinUSD * core)} or ${dec4(priceCOREinETH * core)} ETH)",
                content: """
[address](https://etherscan.io/address/${c.sender}) [txn](https://etherscan.io/tx/${c.tx})
$happies""")
            ..addField(
                name: "Total contribution",
                content:
                    "${dec4(lge3CORE)} CORE, ${dec4(lge3DAI)} DAI, ${dec4(lge3WETH)} WETH (${usd2(lge3COREinUSD + lge3WETHinUSD + lge3DAIinUSD)})")
            ..timestamp = DateTime.now().toUtc();
        } else {
          var hearts = makeHearts(eth, 1024);
          answer = """
<b>Contribution ${dec4(core)} CORE value  (${usd2(priceCOREinUSD * core)} or ${dec4(priceCOREinETH * core)} ETH)</b>
<a href=\"https://etherscan.io/address/${c.sender}\">address</a> <a href="\https://etherscan.io/tx/${c.tx}\">tx</a>
$hearts
<b>Total contribution</b>
${dec4(lge3CORE)} CORE, ${dec4(lge3DAI)} DAI, ${dec4(lge3WETH)} WETH (${usd2(lge3COREinUSD + lge3WETHinUSD + lge3DAIinUSD)})
""";
        }
        wrapper.send(channel.id, answer, markdown: false, disablePreview: true);
      }
    }
  }

  logCoreBought(CoreBought c) {
    for (var channel in [
      priceDiscussionChannel,
      priceAndTradingChat,
      officialChat
    ]) {
      //for (var channel in [robocoreTestChannel, robocoreTestGroup]) {
      var wrapper = channel.getWrapperFromBot(this);
      var answer;
      var core = raw18(c.coreAmt);
      var eth = core * priceCOREinETH;
      if (wrapper is RoboDiscord) {
        var happies = makeHappies(eth, 190);
        answer = EmbedBuilder()
          ..addField(
              name:
                  "Market buy ${dec4(core)} CORE (${usd2(priceCOREinUSD * core)} or ${dec4(priceCOREinETH * core)} ETH)",
              content: """
[address](https://etherscan.io/address/${c.sender}) [txn](https://etherscan.io/tx/${c.tx})
$happies""")
          ..addField(
              name: "Total market bought",
              content:
                  "${dec4(lge3COREBought)} CORE value (${usd2(priceCOREinUSD * lge3COREBought)} or ${dec4(priceCOREinETH * lge3COREBought)} ETH)")
          ..timestamp = DateTime.now().toUtc();
      } else {
        var hearts = makeHearts(eth, 1024);
        answer = """
<b>Market buy ${dec4(core)} CORE (${usd2(priceCOREinUSD * core)} (${dec4(priceCOREinETH * core)} ETH)</b>
<a href=\"https://etherscan.io/address/${c.sender}\">address</a> <a href="\https://etherscan.io/tx/${c.tx}\">tx</a>
$hearts
<b>Total market bought</b>
${dec4(lge3COREBought)} CORE value (${usd2(priceCOREinUSD * lge3COREBought)} or ${dec4(priceCOREinETH * lge3COREBought)} ETH)
""";
      }
      wrapper.send(channel.id, answer, markdown: false, disablePreview: true);
    }
  }
}
