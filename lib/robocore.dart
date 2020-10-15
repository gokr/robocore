import 'dart:async';

import 'package:cron/cron.dart';
import 'package:logging/logging.dart';
import 'package:nyxx/nyxx.dart';
import 'package:robocore/command.dart';
import 'package:robocore/core.dart';
import 'package:robocore/event_logger.dart';
import 'package:robocore/model/swap.dart';
import 'package:robocore/poster.dart';
import 'package:teledart/model.dart';
import 'package:teledart/teledart.dart';
import 'package:teledart/telegram.dart';

import 'database.dart';

Logger log = Logger("Robocore");

abstract class RoboWrapper {
  Robocore bot;
  late String text;
  late List<String> parts;

  RoboWrapper(this.bot);

  runCommands() async {
    logMessage();
    for (var cmd in bot.commands) {
      if (cmd.isValid(this)) {
        return await cmd.exec(this);
      }
    }
    if (isCommand()) reply(randomDNU());
  }

  String randomDNU() {
    return randomOf([
      "I am afraid I can't do that Dave, I mean... ${sender()}",
      "I have absolutely no clue what you are blabbering about",
      "Are you sure I am meant to understand that?",
      "I am no damn AI, what did you mean?",
    ]);
  }

  logMessage();

  bool validCommand(Command cmd);

  bool isCommand() {
    return text.startsWith(prefix);
  }

  // Either ! or /
  String get prefix;

  /// Split a message into distinct words and 'A sentence' or '<some JSON>'
  List<String> splitMessage(String str) {
    return exp.allMatches(str).map((m) => m.group(0) ?? "").toList();
  }

  /// Used to split messages so that parts can be in single quotes (like JSON)
  static final exp = RegExp("[^\\s']+|'[^']*'");

  reply(dynamic answer,
      {bool disablePreview = true, bool markdown = false}) async {}

  dynamic buildHelp();

  // Username of sender
  String sender();
}

class RoboDiscord extends RoboWrapper {
  MessageReceivedEvent e;

  RoboDiscord(Robocore bot, this.e) : super(bot) {
    text = e.message.content.toLowerCase();
    parts = splitMessage(text);
  }

  logMessage() {
    log.info(
        "Command: ${e.message.author}: ${e.message.content} channel: ${e.message.channel.id}");
  }

  String get prefix => discordPrefix;

  bool validCommand(Command cmd) {
    var text = e.message.content;
    return cmd.listChecked(e) &&
        cmd.userChecked(e) &&
        (text.startsWith(discordPrefix + cmd.name) ||
            (cmd.short != "" && (text == discordPrefix + cmd.short) ||
                text.startsWith(discordPrefix + cmd.short + " ")));
  }

  sender() => e.message.author.username;

  reply(dynamic answer,
      {bool disablePreview = true, bool markdown = false}) async {
    if (answer is EmbedBuilder) {
      await e.message.channel.send(embed: answer);
    } else {
      await e.message.channel.send(content: answer);
    }
  }

  EmbedBuilder buildHelp() {
    final embed = EmbedBuilder()
      ..addAuthor((author) {
        author
          ..name = "RoboCORE"
          ..iconUrl = bot.discord.self.avatarURL();
      });
    for (var cmd in bot.commands) {
      embed.addField(name: cmd.syntax, content: cmd.help);
    }
    return embed;
  }

  DiscordColor color() {
    return (e.message.author is CacheMember)
        ? (e.message.author as CacheMember).color
        : DiscordColor.black;
  }

  bool isMention() => e.message.mentions.contains(bot.self);
}

class RoboTelegram extends RoboWrapper {
  TeleDartMessage e;

  RoboTelegram(Robocore bot, this.e) : super(bot) {
    text = e.text.toLowerCase();
    parts = splitMessage(text);
  }

  logMessage() {
    log.info("Command: ${e.from.username}: ${e.text}"); // TODO: channel?
  }

  bool validCommand(Command cmd) {
    var text = e.text;
    return text.startsWith(telegramPrefix + cmd.name) ||
        (cmd.short != "" && (text == telegramPrefix + cmd.short) ||
            text.startsWith(telegramPrefix + cmd.short + " "));
  }

  String get prefix => telegramPrefix;

  sender() => e.from.username ?? "(you have no username!)";

  reply(dynamic answer,
      {bool disablePreview = true, bool markdown = false}) async {
    await e.reply(answer,
        parse_mode: (markdown ? 'MarkdownV2' : 'HTML'),
        disable_web_page_preview: disablePreview);
  }

  String buildHelp() {
    StringBuffer buf = StringBuffer();
    for (var cmd in bot.commands) {
      buf.writeln("<b>${cmd.name}</b>");
      buf.writeln("Syntax: <code>${cmd.syntax}</code>");
      buf.writeln("${cmd.help}");
      buf.writeln("");
    }
    return buf.toString();
  }
}

/// The bot
class Robocore {
  late Map config;
  late Nyxx discord;
  bool discordReady = false;
  late TeleDart teledart;
  bool teledartReady = false;

  // All loggers
  List<EventLogger> loggers = [];

  /// All stickies
  //Map<String, Snowflake> stickies = {};

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
  background() async {
    await updatePriceInfo();
    rewardsInCORE = raw18(await core.cumulativeRewardsSinceStart());
    rewardsInUSD = rewardsInCORE * priceCOREinUSD;

    // Update posters, we copy since it may remove itself from the List in tick
    var ps = await Poster.getAll();
    for (var p in ps) {
      p.tick(this);
    }
  }

  Future<ITextChannel> getChannel(int id) async {
    return await discord.getChannel<ITextChannel>(Snowflake(id.toString()));
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

  String floorStringCORE([num amount = 1]) {
    return "$amount CORE = ${usd2(floorCOREinUSD * amount)} (${dec4(floorCOREinETH * amount)} ETH)";
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
      ..add(MentionCommand())
      ..add(HelpCommand())
      ..add(FAQCommand())
      ..add(StartCommand())
      ..add(StatsCommand())
      ..add(ContractsCommand())
      ..add(LogCommand()
        ..whitelist = [
          759890072392302592,
          764120413507813417,
          763138788297408552
        ]) // price-discussion, robocore, robocore-development
      ..add(PriceCommand())
      ..add(FloorCommand())
      ..add(PosterCommand()
        ..users = [
          124467899447508992,
          298396371789152258,
          751362716962390086,
          757109953910538341
        ]); // gokr, CryptoXman, 0xRevert, X3
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

    // Create our two bots
    discord = Nyxx(config['nyxx']);
    teledart = TeleDart(Telegram(config['teledart']), Event());

    // Create our interface with Ethereum
    core = Core.randomKey(config['apiurl'], config['wsurl']);
    await core.readContracts();

    buildCommands();

    // Run cron
    var cron = Cron();
    // One initial background
    await background();
    log.info("Scheduling 1 minute daemon");
    cron.schedule(new Schedule.parse("*/1 * * * *"), () async {
      log.info('Running background ...');
      await background();
      log.info('Done.');
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
      var wrapper = RoboDiscord(this, event);
      wrapper.runCommands();
    });

    // Hook up to Telegram messages
    teledart.start().then((me) {
      log.info('RoboCORE in Telegram is ready!');
      teledartReady = true;
    });

    teledart
        .onMessage(entityType: 'bot_command')
        .listen((TeleDartMessage message) async {
      var wrapper = RoboTelegram(this, message);
      wrapper.runCommands();
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
  }
}
