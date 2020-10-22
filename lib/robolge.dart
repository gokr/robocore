import 'dart:io';
import 'dart:math';

import 'package:logging/logging.dart';
import 'package:robocore/core.dart';
import 'package:robocore/etherscan.dart';
import 'package:robocore/model/contribution.dart';
import 'package:robocore/model/corebought.dart';
import 'package:robocore/model/holder.dart';
import 'package:robocore/model/swap.dart';
import 'package:robocore/poster.dart';
import 'package:robocore/uniswap.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

import 'database.dart';

Logger log = Logger("Roboserver");

/// Server
class RoboLGE {
  late Map config;

  /// To interact with Ethereum contracts
  late Core core;

  // APIs
  late Etherscan scan;
  late Uniswap uniswap;

  RoboLGE(this.config);

  start() async {
    await openDatabase(config);
    log.info("Postgres opened: ${db.databaseName}");

    try {
      await Swap.createTable();
      await Contribution.createTable();
      await CoreBought.createTable();
      await Poster.createTable();
      await Holder.createTable();
      log.info("Created tables");
    } catch (e) {
      log.warning(e);
      exit(1);
    }

    // Etherscan
    scan = Etherscan(config['etherscan']);

    // Uniswap
    uniswap = Uniswap(); //config['uniswap']);
    await uniswap.connect();

    // Create our interface with Ethereum
    core = Core.randomKey(config['apiurl'], config['wsurl']);
    await core.readContracts();
  }

  // The functions we are looking at, to distinguish txns
  static const String addLiquidityETH = "ed995307";
  static const String addLiquidityWithTokenWithAllowance = "14711c9d";
  static const String addLiquidityAtomic = "39c168e2";
  static const String changeAdmin = "8f283970";
  static const String admin = "f851a440";

  static const String contributionTopic =
      "0x41892ddb04331614cc8d0b2be5d92c744beb730ffd9677993a8813e339414dde";
  static const String coreBoughtTopic =
      "0x58fb9096ebae0b9f0d1bcf89f5ff3d68fcce504b2352307c39d97481c5047b34";
  static const String transferTopic =
      "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef";

  //var addETH = core.LGE2.function("addLiquidityETH");

  List<FilterEvent> findContributionEvents(List<FilterEvent> logs) {
    return logs.where((log) => log.topics.contains(contributionTopic)).toList();
  }

  List<FilterEvent> findTransferEvents(List<FilterEvent> logs) {
    return logs.where((log) => log.topics.first == transferTopic).toList();
  }

  EthereumAddress tokenOfSwapTransfer(FilterEvent transfer) {
    assert(transfer.topics.first == transferTopic);
    var src = transfer.topics[1];
    var adr = EthereumAddress.fromHex(hexToInt(src).toRadixString(16));
    if (adr == core.CORE2ETHAddr) {
      return core.CORE2ETHAddr;
    } else if (adr == core.WBTC2ETHAddr) {
      return core.WBTC2ETHAddr;
    } else {
      throw "Unknown COIN deposit";
    }
  }

  EthereumAddress tokenOfTokenTransfer(FilterEvent transfer) {
    assert(transfer.topics.first == transferTopic);
    var adr = transfer.address;
    if (adr == core.coreAddr) {
      return core.coreAddr;
    } else if (adr == core.wethAddr) {
      return core.wethAddr;
    } else if (adr == core.wbtcAddr) {
      return core.wbtcAddr;
    } else if (adr == core.WBTC2ETHAddr) {
      return core.WBTC2ETHAddr;
    } else {
      throw "Unknown COIN deposit";
    }
  }

  String symbolOfDepositToken(EthereumAddress adr) {
    if (adr == core.coreAddr) {
      return 'CORE';
    } else if (adr == core.wethAddr) {
      return 'WETH';
    } else if (adr == core.wbtcAddr) {
      return 'WBTC';
    } else if (adr == core.WBTC2ETHAddr) {
      return 'WBTC/ETH LP';
    } else {
      throw "Unknown COIN";
    }
  }

  String symbolOfSwap(EthereumAddress adr) {
    if (adr == core.CORE2ETHAddr) {
      return 'CORE';
    } else if (adr == core.WBTC2ETHAddr) {
      return 'WBTC';
    } else {
      throw "Unknown COIN swap";
    }
  }

  String symbolOfTokenTransfer(EthereumAddress adr) {
    if (adr == core.coreAddr) {
      return 'CORE';
    } else if (adr == core.wethAddr) {
      return 'WETH';
    } else if (adr == core.wbtcAddr) {
      return 'WBTC';
    } else {
      throw "Unknown COIN deposit";
    }
  }

  processTransfers(
      TransactionInformation tx, List<FilterEvent> logs, Contribution c) {}

  Future<BigInt> coreValueOfWBTC(BigInt amount, BlockNum block) async {
    var priceCOREinETH = await uniswap.pairPriceAt(block, core.CORE2ETHAddr);
    var priceWBTCinETH = await uniswap.pairPriceAt(block, core.WBTC2ETHAddr);
    return BigInt.from(
        pow(10, 18) * ((raw8(amount) * priceWBTCinETH) / priceCOREinETH));
  }

  List<FilterEvent> transfersToLGE(List<FilterEvent> transfers) {
    return transfers
        .where((element) =>
            element.topics.last ==
            '0x000000000000000000000000f7ca8f55c54cbb6d0965bc6d65c43adc500bc591')
        .toList();
  }

  // Print and stuff into buffer
  logprint(StringBuffer log, String line) {
    print(line);
    log.writeln(line);
  }

  recreateHistory() async {
    var contribs = await Contribution.getAll();
    // Various bags to collect txns to see at the end, nothing important.
    var atomics = [];
    var mended = [];
    var changeAdmins = [];
    var admins = [];
    var eths = [];
    var tokens = [];
    var lps = [];

    // Loop over all, we should also make a GraphQL thing later,
    // to make sure we have all Contrib events collected.
    for (var contrib in contribs) {
      var l = StringBuffer();
      // If holder is not created/mapped yet
      var holder = await Holder.findOrCreateHolder(contrib);
      if (contrib.holder == null) {
        contrib.holder = holder.id;
      }
      // Print URL to txn, for easier debuggin
      var ethUrl = "https://etherscan.io/tx/${contrib.tx}";
      logprint(l, ethUrl);

      // Look up tx
      var tx = await core.ethClient.getTransactionByHash(contrib.tx);

      // Find function called
      var fn = bytesToHex(tx.input.sublist(0, 4));

      // All cases

      // ETH will be used to market buy CORE or wBTC, depending on the current allocation.
      // wBTC will be used to market buy CORE or remain as wBTC depending on the current allocation
      // CORE will be used to maintain the peg. It cannot be sold. If the contract receives too much CORE it refunds it proportionally.
      // wBTC/ETH UNI LP tokens will be unwrapped automatically and ETH+wBTC will be distributed following the rules above.

      // CORE, ETH, WETH, WBTC, WBTC/ETH LP
      // coreValue is set when it was ETH, WETH or WBTC/ETH LP (part of which is ETH)

      // Verify Contribution event
      var rc = await core.ethClient.getTransactionReceipt(contrib.tx);
      var logs = rc.logs;
      var cos = findContributionEvents(logs);
      if (cos.length == 0) {
        // Should never happen
        throw "No Contribution event found in logs for txn";
      }
      if (contrib.units > BigInt.parse("65487333214482957510")) {
        print("break");
      }
      // Putting coreValue back into the Contribution (for some reason I may
      // end up with zero sometimes, could be a bug in the web3 lib).
      if (cos.length == 1) {
        var co = cos.first;
        var cv = hexToInt(co.data.substring(2, 66));
        if (contrib.coreValue != cv) {
          print("Ok, mending coreValue");
          contrib.coreValue = cv;
          mended.add(tx);
        }
      } else {
        // Should never happen
        throw "Should be only one Contribution event per txn!";
      }

      // Which function called? We only have two relevant ones
      switch (fn) {
        case addLiquidityETH:
          logprint(l,
              "addLiquidityETH: ${tx.value.getInEther} coreValue: ${raw18(contrib.coreValue)}");
          if (contrib.coreValue == BigInt.zero) {
            // Should not happen
            throw "Bad coreValue still zero!";
          }
          eths.add(tx);
          // Find all transfers
          var transfers = findTransferEvents(logs);
          // but only those to the LGE contract
          var toLGE = transfersToLGE(transfers);
          // Should only be one with this function!
          assert(toLGE.length == 1);
          var trans = toLGE.first;
          // Pick out amount and token from Transfer
          var amount = hexToInt(trans.data);
          var token = tokenOfSwapTransfer(trans);

          // Could have been market buy of CORE or WBTC
          if (token == core.CORE2ETHAddr) {
            // ETH was deposited and caused a buy of CORE
            var priceCOREinETH =
                await uniswap.pairPriceAt(tx.blockNumber, core.CORE2ETHAddr);
            logprint(l, "Price: $priceCOREinETH ETH/CORE");
            var coreHistoric = tx.value.getInEther.toDouble() / priceCOREinETH;
            logprint(l, "Historic value in CORE: $coreHistoric");
            logprint(
                l, "Transfer amount: ${raw18(amount)} ${symbolOfSwap(token)}");
            logprint(l, "Using amount ${raw18(amount)}");
            contrib.units = amount;
          } else if (token == core.WBTC2ETHAddr) {
            // ETH was deposited and caused a buy of WBTC
            var priceCOREinETH =
                await uniswap.pairPriceAt(tx.blockNumber, core.CORE2ETHAddr);
            logprint(l, "Price: $priceCOREinETH ETH/CORE");
            var coreHistoric = tx.value.getInEther.toDouble() / priceCOREinETH;
            logprint(
                l, "Historic value of deposited ETH in CORE: $coreHistoric");
            var coreHistoric2 = await coreValueOfWBTC(amount, tx.blockNumber);
            logprint(
                l, "Historic value of WBTC in CORE: ${raw18(coreHistoric2)}");
            logprint(
                l, "Transfer amount: ${raw8(amount)} ${symbolOfSwap(token)}");
            logprint(l, "Using historic value ${raw18(coreHistoric2)}");
            contrib.units = coreHistoric2;
          }
          // Just for info in db
          contrib.coin = 'ETH';
          break;
        case addLiquidityWithTokenWithAllowance:
          logprint(l,
              "addLiquidityWithTokenWithAllowance: ${tx.value.getInEther} coreValue: ${raw18(contrib.coreValue)}");
          // Token param, just for info
          var depositToken = EthereumAddress.fromHex(
              hexToInt(bytesToHex(tx.input.sublist(5, 36))).toRadixString(16));
          contrib.coin = symbolOfDepositToken(depositToken);
          tokens.add(tx);
          // All transfers
          var transfers = findTransferEvents(logs);
          // All to the LGE contract
          var toLGE = transfersToLGE(transfers);
          var units = BigInt.zero;
          // Used for LP logic, see below
          bool firstTime = true;
          for (var trans in toLGE) {
            // We look at contract emitting transfer to know what it was!
            var token = tokenOfTokenTransfer(trans);
            // We don't care for WBTC-ETH LPs, those are broken up, and cause two more transfers into the contract
            if (token != core.WBTC2ETHAddr) {
              var amount = hexToInt(trans.data);
              if (token == core.coreAddr) {
                // CORE came in, we take it as it is
                logprint(l,
                    "Transfer amount: ${raw18(amount)} ${symbolOfTokenTransfer(token)}");
                logprint(l, "Using amount ${raw18(amount)}");
                units += amount;
              } else if (token == core.wethAddr) {
                // ETH came in, we ignore because LGE will use it to buy CORE or WBTC
                logprint(l,
                    "Ignoring transfer amount: ${raw18(amount)} ${symbolOfTokenTransfer(token)}");
              } else if (token == core.wbtcAddr) {
                // WBTC came in, we have two scenarios:
                // a) it was the result of a market buy, we should value it
                // b) it was the result of an LP breakup, LGE will swap it so we should ignore!
                // If original token was the LP, then the first incoming WBTC will be the breakup to ignore.
                if (depositToken == core.WBTC2ETHAddr && firstTime) {
                  // It's b, we ignore it!
                  firstTime = false;
                } else {
                  // It's a, we value it via WBTC->ETH->CORE
                  var coreHistoric =
                      await coreValueOfWBTC(amount, tx.blockNumber);
                  logprint(l,
                      "Historic value of WBTC in CORE: ${raw18(coreHistoric)}");
                  logprint(l,
                      "Transfer amount: ${raw8(amount)} ${symbolOfTokenTransfer(token)}");
                  logprint(l, "Using historic value ${raw18(coreHistoric)}");
                  units += coreHistoric;
                }
              } else {
                throw "Unknown incoming transfer, should not happen";
              }
            } else {
              logprint(l, "Ignoring breaking up WBTC-ETH LP");
              lps.add(tx);
            }
          }
          contrib.units = units;
          break;
        case addLiquidityAtomic:
          logprint(l, "addLiquidityAtomic: ${tx.value}");
          atomics.add(tx);
          break;
        case changeAdmin:
          logprint(l, "changeAdmin: ${tx.value}");
          changeAdmins.add(tx);
          break;
        case admin:
          logprint(l, "admin: ${tx.value}");
          admins.add(tx);
          break;
        default:
          throw "Unknown function called";
      }
      // Finally save Contribution with log
      contrib.log = l.toString();
      await contrib.update();
      print("------------------------------------------------");
    }
    print("Done");
  }

  checkContract() async {}
}
