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

  recreateHistory() async {
    var contribs = await Contribution.getAll();
    var atomics = [];
    var bad = [];
    var mended = [];
    var changeAdmins = [];
    var admins = [];
    var eths = [];
    var tokens = [];
    var lps = [];
    for (var contrib in contribs) {
      var holder = await Holder.findOrCreateHolder(contrib);
      // If holder is not mapped yet, we do it
      if (contrib.holder == null) {
        contrib.holder = holder.id;
        await contrib.update();
      }
      // Find tx info
      var ethUrl = "https://etherscan.io/tx/${contrib.tx}";
      print("https://etherscan.io/tx/${contrib.tx}");
      var tx = await core.ethClient.getTransactionByHash(contrib.tx);
      // Find function called
      var fn = bytesToHex(tx.input.sublist(0, 4));

      // All other cases

      // ETH will be used to market buy CORE or wBTC, depending on the current allocation.
      // wBTC will be used to market buy CORE or remain as wBTC depending on the current allocation
      // CORE will be used to maintain the peg. It cannot be sold. If the contract receives too much CORE it refunds it proportionally.
      // wBTC/ETH UNI LP tokens will be unwrapped automatically and ETH+wBTC will be distributed following the rules above.*/

      // CORE, ETH, WETH, WBTC, WBTC/ETH LP
      // coreValue is set when it was ETH, WETH or WBTC/ETH LP (part of which is ETH)

      // Verify Contribution event
      var rc = await core.ethClient.getTransactionReceipt(contrib.tx);
      var logs = rc.logs;
      var cos = findContributionEvents(logs);
      if (cos.length == 0) {
        print("BAD APPLE! $ethUrl");
        bad.add(tx);
      }
      if (contrib.units > BigInt.parse("65487333214482957510")) {
        print("break");
      }
      if (cos.length == 1) {
        var co = cos.first;
        var cv = hexToInt(co.data.substring(2, 66));
        if (contrib.coreValue != cv) {
          print("Ok, mending coreValue");
          contrib.coreValue = cv;
          await contrib.update();
          mended.add(tx);
        }
      } else {
        throw "Should be only one Contribution event per txn!";
      }

      // Which function called?
      switch (fn) {
        case addLiquidityETH:
          print(
              "addLiquidityETH: ${tx.value} coreValue: ${raw18(contrib.coreValue)}");
          if (contrib.coreValue == BigInt.zero) {
            throw "Bad coreValue still zero!";
          }
          eths.add(tx);
          // All transfers
          var transfers = findTransferEvents(logs);
          // All to the LGE contract
          var toLGE = transfers
              .where((element) =>
                  element.topics.last ==
                  '0x000000000000000000000000f7ca8f55c54cbb6d0965bc6d65c43adc500bc591')
              .toList();
          // Should only be one with this function!
          assert(toLGE.length == 1);
          var trans = toLGE.first;
          // Pick out amount and token from Transfer
          var amount = hexToInt(trans.data);
          var token = tokenOfSwapTransfer(trans);
          if (token == core.CORE2ETHAddr) {
            // ETH was deposited and caused a buy of CORE
            var priceCOREinETH =
                await uniswap.pairPriceAt(tx.blockNumber, token);
            print("Price: $priceCOREinETH ETH/CORE");
            var coreHistoric = tx.value.getInEther.toDouble() / priceCOREinETH;
            print("Historic value in CORE: $coreHistoric");
            print("Transfer amount: ${raw18(amount)},  ${symbolOfSwap(token)}");
            print("Using amount");
            contrib.units = amount;
          } else if (token == core.WBTC2ETHAddr) {
            // ETH was deposited and caused a buy of WBTC
            var priceCOREinETH =
                await uniswap.pairPriceAt(tx.blockNumber, token);
            print("Price: $priceCOREinETH ETH/CORE");
            var coreHistoric = tx.value.getInEther.toDouble() / priceCOREinETH;
            print("Historic value of ETH in CORE: $coreHistoric");
            var coreHistoric2 = await coreValueOfWBTC(amount, tx.blockNumber);
            print("Historic value of WBTC in CORE: ${raw18(coreHistoric2)}");
            print("Transfer amount: ${raw8(amount)},  ${symbolOfSwap(token)}");
            print("Using historic value of WBTC in CORE");
            contrib.units = coreHistoric2;
          }
          contrib.coin = 'ETH';
          await contrib.update();
          break;
        case addLiquidityWithTokenWithAllowance:
          print(
              "addLiquidityWithTokenWithAllowance: ${tx.value} coreValue: ${raw18(contrib.coreValue)}");
          // Token param
          var token = EthereumAddress.fromHex(
              hexToInt(bytesToHex(tx.input.sublist(5, 36))).toRadixString(16));
          contrib.coin = symbolOfDepositToken(token);
          tokens.add(tx);
          // All transfers
          var transfers = findTransferEvents(logs);
          // All to the LGE contract, but we look at contract emitting transfer!
          var toLGE = transfers
              .where((element) =>
                  element.topics.last ==
                  '0x000000000000000000000000f7ca8f55c54cbb6d0965bc6d65c43adc500bc591')
              .toList();
          var units = BigInt.zero;
          for (var trans in toLGE) {
            var token = tokenOfTokenTransfer(trans);
            // We don't care for WBTC-ETH LPs, those are broken up, burned and cause more transfers
            if (token != core.WBTC2ETHAddr) {
              var amount = hexToInt(trans.data);
              if (token == core.coreAddr) {
                // CORE was deposited, we take it as it is
                print(
                    "Transfer amount: ${raw18(amount)},  ${symbolOfTokenTransfer(token)}");
                print("Using amount");
                units += amount;
              } else if (token == core.wethAddr) {
                print(
                    "Ignoring transfer amount: ${raw18(amount)},  ${symbolOfTokenTransfer(token)}");
              } else if (token == core.wbtcAddr) {
                // WBTC was deposited, we value it via WBTC->ETH->CORE
                var coreHistoric =
                    await coreValueOfWBTC(amount, tx.blockNumber);
                print("Historic value of WBTC in CORE: ${raw18(coreHistoric)}");
                print(
                    "Transfer amount: ${raw8(amount)},  ${symbolOfTokenTransfer(token)}");
                print("Using historic value");
                units += coreHistoric;
              } else {
                print("Ehum");
              }
            } else {
              print("Ignoring breaking up WBTC-ETH LP");
              lps.add(tx);
            }
          }
          contrib.units = units;
          await contrib.update();
          break;
        case addLiquidityAtomic:
          print("addLiquidityAtomic: ${tx.value}");
          atomics.add(tx);
          break;
        case changeAdmin:
          print("changeAdmin: ${tx.value}");
          changeAdmins.add(tx);
          break;
        case admin:
          print("admin: ${tx.value}");
          admins.add(tx);
          break;
        default:
          throw "Unknown function called";
      }
      print("------------------------------------------------");
    }
    print("Done");
  }

  checkContract() async {}
}
