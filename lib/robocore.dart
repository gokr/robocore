import 'dart:async';
import 'dart:io';
import 'package:logging/logging.dart';
import 'package:neat_periodic_task/neat_periodic_task.dart';
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

var gokr = RoboUser.both(124467899447508992, 1156133961);
var CryptoXman = RoboUser.discord(298396371789152258);
var xRevert = RoboUser.discord(751362716962390086);
var X3 = RoboUser.discord(757109953910538341);

var priceDiscussionChannel = DiscordChannel(759890072392302592);
var robocoreChannel = DiscordChannel(764120413507813417);
var robocoreDevelopmentChannel = DiscordChannel(763138788297408552);

// For tests
var robocoreTestGroup = TelegramChannel(-440184090);
var robocoreTestChannel = DiscordChannel(762629759393726464);
var robocoreTestChannelLogger = DiscordChannel(763910363439431700);

abstract class RoboWrapper {
  Robocore bot;

  RoboWrapper(this.bot);

  Future<dynamic> getChannelOrChat(int id) async {}

  Future<int?> send(int channelOrChatId, dynamic content,
      {bool disablePreview = true, bool markdown = true}) async {}

  Future pinMessage(int channelOrChatId, int id) async {}

  Future<dynamic> getMessage(int channelOrChatId, int id) async {}

  Future<dynamic> editMessage(int channel, int id, dynamic content) async {}

  deleteMessage(int channelOrChatId, int id) async {}

  /// Split a message into distinct words and 'A sentence' or '<some JSON>'
  List<String> splitMessage(String str) {
    return exp.allMatches(str).map((m) => m.group(0) ?? "").toList();
  }

  /// Used to split messages so that parts can be in single quotes (like JSON)
  static final exp = RegExp("[^\\s']+|'[^']*'");
}

mixin RoboMessage on RoboWrapper {
  /// Find a Command valid for this message and let it handle it
  runCommands() async {
    logMessage();
    for (var cmd in bot.commands) {
      if (cmd.isValid(this)) {
        return await cmd.handleMessage(this);
      }
    }
    if (isCommand()) reply(randomDNU());
  }

  String randomDNU() {
    return randomOf([
      "I am afraid I can't do that Dave, I mean... ${username}",
      "I have absolutely no clue what you are blabbering about",
      "Are you sure I am meant to understand that?",
      "I am no damn AI, what did you mean?",
    ]);
  }

  logMessage() {
    log.info("$roboChannel ($username): $text");
  }

  bool isCommand() {
    return text.startsWith(prefix);
  }

  bool isMention();

  /// Either ! or /
  String get prefix;

  // Is this command valid to execute for this message?
  bool validCommand(Command cmd) {
    // Some commands are valid for all in DM, or for select users with access
    if (isDirectChat) {
      return (cmd.validForAllInDM || cmd.validForUser(roboUser)) &&
          matches(cmd);
    } else {
      // Otherwise we check whitelist/blacklist of channel ids && users with access
      return cmd.validForChannel(roboChannel) &&
          cmd.validForUser(roboUser) &&
          matches(cmd);
    }
  }

  bool matches(Command cmd) {
    return (text.startsWith(prefix + cmd.name) ||
        (cmd.short != "" && (text == prefix + cmd.short) ||
            text.startsWith(prefix + cmd.short + " ")));
  }

  /// The actual message text
  String get text;
  String get textLowerCase;

  List<String> get parts;

  /// Returns a channel (Discord) or chat (Telegram)
  RoboChannel get roboChannel;

  /// Returns a RoboUser
  RoboUser get roboUser;

  /// Username of sender
  String get username;

  /// Is this a Direct Chat (DM. PM)?
  bool get isDirectChat;

  reply(dynamic answer,
      {bool disablePreview = true, bool markdown = false}) async {}

  dynamic buildHelp();
}

class RoboDiscord extends RoboWrapper {
  RoboDiscord(Robocore bot) : super(bot);

  Future<dynamic> getChannelOrChat(int id) async {
    return await bot.getDiscordChannel(id);
  }

  Future<dynamic> getMessage(int channel, id) async {
    var ch = await bot.getDiscordChannel(channel);
    return ch.getMessage(Snowflake(id));
  }

  Future<dynamic> deleteMessage(int channel, id) async {
    var message = await getMessage(channel, id);
    message?.delete();
  }

  Future<dynamic> editMessage(int channel, int id, dynamic content) async {
    var message = await getMessage(channel, id);
    if (content is EmbedBuilder) {
      await message.edit(embed: content);
    } else {
      await message.edit(content: content);
    }
  }

  Future<int> send(int channelId, dynamic content,
      {bool disablePreview = true, bool markdown = true}) async {
    var channel = await bot.getDiscordChannel(channelId);
    dynamic message;
    if (content is EmbedBuilder) {
      message = await channel.send(embed: content);
    } else {
      message = await channel.send(content: content);
    }
    return message.id.id;
  }

  Future<dynamic> pinMessage(int channel, id) async {
    var message = await getMessage(channel, id);
    message.pinMessage();
  }

  Future<dynamic> _send(ITextChannel channel, dynamic content) async {
    if (content is EmbedBuilder) {
      return await channel.send(embed: content);
    } else {
      return await channel.send(content: content);
    }
  }
}

class RoboTelegram extends RoboWrapper {
  RoboTelegram(Robocore bot) : super(bot);

  Future<dynamic> getChannelOrChat(int id) async {
    return await bot.getTelegramChat(id);
  }

  Future<dynamic> deleteMessage(int chat, id) async {
    return bot.teledart.telegram.deleteMessage(chat, id);
  }

  Future<dynamic> editMessage(int chatId, int id, dynamic content,
      {bool disablePreview = true, bool markdown = true}) async {
    return bot.teledart.telegram.editMessageText(content,
        chat_id: chatId,
        message_id: id,
        parse_mode: (markdown ? 'MarkdownV2' : 'HTML'),
        disable_web_page_preview: disablePreview);
  }

  Future<int?> send(int chatId, dynamic content,
      {bool disablePreview = true, bool markdown = true}) async {
    var message = await bot.teledart.telegram.sendMessage(chatId, content,
        parse_mode: (markdown ? 'MarkdownV2' : 'HTML'),
        disable_web_page_preview: disablePreview);
    return message.message_id;
  }

  Future<dynamic> pinMessage(int chat, id) async {
    return bot.teledart.telegram.pinChatMessage(chat, id);
  }
}

class RoboDiscordMessage extends RoboDiscord with RoboMessage {
  MessageReceivedEvent e;
  late String text, textLowerCase;
  late List<String> parts;

  RoboDiscordMessage(Robocore bot, this.e) : super(bot) {
    text = e.message.content;
    textLowerCase = text.toLowerCase();
    parts = splitMessage(text);
  }

  String get prefix => discordPrefix;
/*
  // Is this command valid to execute for this message?
  bool validCommand(Command cmd) {
    // Some commands are valid for all in DM, or for select users with access
    if (isDirectChat) {
      return (cmd.validForAllInDM || cmd.validForUser(roboUser)) &&
          matches(cmd);
    } else {
      // Otherwise we check whitelist/blacklist of channel ids && users with access
      return cmd.validForChannel(roboChannel) &&
          cmd.validForUser(roboUser) &&
          matches(cmd);
    }
  }


  bool matches(Command cmd) {
    return (text.startsWith(discordPrefix + cmd.name) ||
        (cmd.short != "" && (text == discordPrefix + cmd.short) ||
            text.startsWith(discordPrefix + cmd.short + " ")));
  }
*/
  String get username => e.message.author.username;
  RoboUser get roboUser => RoboUser.discord(e.message.author.id.id);
  RoboChannel get roboChannel => DiscordChannel(e.message.channelId.id);
  bool get isDirectChat => e.message.channel.type == ChannelType.dm;

  reply(dynamic answer,
      {bool disablePreview = true, bool markdown = false}) async {
    return _send(e.message.channel, answer);
  }

  EmbedBuilder buildHelp() {
    final embed = EmbedBuilder()
      ..addAuthor((author) {
        author
          ..name = "RoboCORE"
          ..iconUrl = bot.nyxx.self.avatarURL();
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

class RoboTelegramMessage extends RoboTelegram with RoboMessage {
  TeleDartMessage e;
  late String text, textLowerCase;
  late List<String> parts;

  RoboTelegramMessage(Robocore bot, this.e) : super(bot) {
    text = e.text;
    textLowerCase = text.toLowerCase();
    parts = splitMessage(text);
  }

/*
  // In Telegram all commands are valid
  bool validCommand(Command cmd) {
    var text = e.text;
    return text.startsWith(telegramPrefix + cmd.name) ||
        (cmd.short != "" && (text == telegramPrefix + cmd.short) ||
            text.startsWith(telegramPrefix + cmd.short + " "));
  }
*/
  String get prefix => telegramPrefix;

  String get username => e.from.username ?? "(you have no username!)";
  RoboUser get roboUser => RoboUser.telegram(e.from.id);
  RoboChannel get roboChannel => TelegramChannel(e.chat.id);
  bool get isDirectChat => e.chat.type == "private";

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

  @override
  bool isMention() =>
      text.contains("@robocore_bot") || text.contains("@robocoretest_bot");
}

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

  /// All stickies
  //Map<String, Snowflake> stickies = {};

  /// To interact with Ethereum contracts
  late Core core;

  late StreamSubscription subscription;

  ClientUser get self => nyxx.self;

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

  late num lge2CORE, lge2COREinUSD, lge2ETH, lge2ETHinUSD, lge2WrapToken;

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
    try {
      await updateRewardsInfo();
    } catch (e, s) {
      log.warning("Exception during update of rewards info", e, s);
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

  updateLGE2Info() async {
    lge2CORE = raw18(await core.lge2TotalCOREContributed());
    lge2COREinUSD = lge2CORE * priceCOREinUSD;
    lge2ETH = raw18(await core.lge2TotalETHContributed());
    lge2ETHinUSD = lge2ETH * priceETHinUSD;
    lge2WrapToken = raw18(await core.lge2TotalWrapTokenContributed());
    //lge2WrapTokeninUSD = lge2WrapToken *
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

  updateRewardsInfo() async {
    rewardsInCORE = raw18(await core.cumulativeRewardsSinceStart());
    rewardsInUSD = rewardsInCORE * priceCOREinUSD;
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
      ..add(LGE2StatsCommand())
      ..add(ContractsCommand())
      ..add(LogCommand()
        ..validForAllInDM = true
        ..users = [gokr, CryptoXman, xRevert, X3]
        ..whitelist = [
          priceDiscussionChannel,
          robocoreTestGroup,
          robocoreChannel,
          robocoreDevelopmentChannel
        ])
      ..add(PriceCommand())
      ..add(FloorCommand())
      ..add(IdCommand())
      ..add(AdminCommand()..users = [gokr])
      ..add(PosterCommand()..users = [gokr, CryptoXman, xRevert, X3]);
  }

  /// Go through all loggers and let them log if they want to
  performLogging(Swap swap) {
    for (var logger in loggers) {
      logger.log(this, swap);
    }
  }

  start() async {
    await openDatabase(config);
    log.info("Postgres opened: ${db.databaseName}");

    // Create our two bots
    nyxx = Nyxx(config['nyxx'], useDefaultLogger: false);
    teledart = TeleDart(Telegram(config['teledart']), Event());

    // Create abstraction wrappers
    discord = RoboDiscord(this);
    telegram = RoboTelegram(this);

    // Create our interface with Ethereum
    core = Core.randomKey(config['apiurl'], config['wsurl']);
    await core.readContracts();

    buildCommands();

    // One initial update
    await updatePriceInfo();

    // We listen to all Swaps on COREETH
    subscription = core.listenToEvent(core.CORE2ETH, 'Swap', (ev, event) {
      //print("Topics: ${event.topics} data: ${event.data}");
      var swap = Swap.from(ev, event);
      updatePriceInfo();
      performLogging(swap);
    });

    // When we are ready in Discord
    nyxx.onReady.listen((ReadyEvent e) async {
      log.info("Robocore in Discord is ready!");
      discordReady = true;
      await updateUsername();
    });

    // All Discord messages
    nyxx.onMessageReceived.listen((MessageReceivedEvent event) async {
      RoboDiscordMessage(this, event).runCommands();
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
      RoboTelegramMessage(this, message).runCommands();
    });

    // All Telegram messages mentioning me
    teledart
        .onMessage(entityType: 'mention')
        .listen((TeleDartMessage message) async {
      RoboTelegramMessage(this, message).runCommands();
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

    // Base background tasks are run every 10 seconds
    final scheduler = NeatPeriodicTaskScheduler(
      interval: Duration(seconds: 10),
      name: 'background',
      timeout: Duration(seconds: 5),
      task: () async => background(),
      minCycle: Duration(seconds: 5),
    );

    scheduler.start();
    await ProcessSignal.sigterm.watch().first;
    await scheduler.stop();
  }
}
