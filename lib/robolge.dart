import 'dart:io';
import 'dart:math';

import 'package:logging/logging.dart';
import 'package:robocore/core.dart';
import 'package:robocore/etherscan.dart';
import 'package:robocore/model/contribution.dart';
import 'package:robocore/model/corebought.dart';
import 'package:robocore/model/holder.dart';
import 'package:robocore/model/swap.dart';
import 'package:robocore/model/poster.dart';
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

  Future<BigInt> coreValueOfWBTC(
      BigInt amount, BlockNum block, StringBuffer l) async {
    var priceCOREinETH = await uniswap.pairPriceAt(block, core.CORE2ETHAddr);
    logprint(l, "Price: $priceCOREinETH ETH/CORE");
    var priceWBTCinETH = await uniswap.pairPriceAt(block, core.WBTC2ETHAddr);
    logprint(l, "Price: $priceWBTCinETH ETH/WBTC");
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

  bool existsThreeTransfers(List<FilterEvent> transfers) {
    int count = 0;
    var coreOrwbtc = [core.wbtcAddr, core.coreAddr];
    for (var t in transfers) {
      if (coreOrwbtc.contains(tokenOfTokenTransfer(t))) count++;
    }
    return count == 3;
  }

  // Print and stuff into buffer
  logprint(StringBuffer log, String line) {
    print(line);
    log.writeln(line);
  }

  recreateHistory(bool incremental) async {
    List<Contribution> contribs;
    if (incremental) {
      contribs = await Contribution.getUnprocessed();
    } else {
      contribs = await Contribution.getAll();
    }
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
      /*var lls = await core.ethClient.getLogs(FilterOptions(
          fromBlock: BlockNum.exact(11076244),
          toBlock: BlockNum.exact(11109131),
          address: core.LGE2Addr,
          topics: [
            [contributionTopic]
          ]));*/
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
          // Should only be one transfer to LGE
          assert(toLGE.length == 1);
          var trans = toLGE.first;
          // Pick out amount and token from Transfer
          var amount = hexToInt(trans.data);
          var token = tokenOfSwapTransfer(trans);

          // Either this was a market buy of CORE or WBTC
          if (token == core.CORE2ETHAddr) {
            // ETH was deposited and caused a buy of CORE
            var priceCOREinETH =
                await uniswap.pairPriceAt(tx.blockNumber, core.CORE2ETHAddr);
            logprint(l, "Price: $priceCOREinETH ETH/CORE");
            var coreHistoric = tx.value.getInEther.toDouble() / priceCOREinETH;
            logprint(l, "Historic value in CORE: $coreHistoric");
            logprint(
                l, "Transfer amount: ${raw18(amount)} ${symbolOfSwap(token)}");
            logprint(l, "* Adding units amount ${raw18(amount)}");
            contrib.units = amount;
          } else if (token == core.WBTC2ETHAddr) {
            // ETH was deposited and caused a buy of WBTC
            var priceCOREinETH =
                await uniswap.pairPriceAt(tx.blockNumber, core.CORE2ETHAddr);
            var coreHistoric = tx.value.getInEther.toDouble() / priceCOREinETH;
            logprint(
                l, "Historic value of deposited ETH in CORE: $coreHistoric");
            var coreHistoric2 =
                await coreValueOfWBTC(amount, tx.blockNumber, l);
            logprint(
                l, "Historic value of WBTC in CORE: ${raw18(coreHistoric2)}");
            logprint(
                l, "Transfer amount: ${raw8(amount)} ${symbolOfSwap(token)}");
            logprint(
                l, "* Adding units historic value ${raw18(coreHistoric2)}");
            contrib.units = coreHistoric2;
          }
          // Just for info in db
          contrib.coin = 'ETH';
          break;
        case addLiquidityWithTokenWithAllowance:
          logprint(l,
              "addLiquidityWithTokenWithAllowance: ${tx.value.getInEther} coreValue: ${raw18(contrib.coreValue)}");
          // Token param, the original token added: CORE, WBTC, WBTC/ETH LP
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
            // We look at contract emitting the transfer to know what it was!
            var token = tokenOfTokenTransfer(trans);
            var amount = hexToInt(trans.data);

            // CORE came in as a transfer, we can take it as it is because we never sell CORE
            if (token == core.coreAddr) {
              logprint(l,
                  "Transfer amount: ${raw18(amount)} ${symbolOfTokenTransfer(token)}");
              logprint(l, "* Adding units amount ${raw18(amount)}");
              units += amount;
            } else if (token == core.wethAddr) {
              // We always ignore WETH because it is always swapped to something else
              logprint(l,
                  "Ignoring transfer amount: ${raw18(amount)} ${symbolOfTokenTransfer(token)}");
            } else {
              // Three cases, original deposit of CORE, WBTC or WBTC/ETH LP
              if (depositToken == core.WBTC2ETHAddr) {
                if (token == core.wbtcAddr) {
                  // The first WBTC part Transfer may be kept, or may be swapped to something else.
                  // We can decide if we should count it by looking at all transfers to LGE
                  // containing either CORE or WBTC. If there are three, this first one
                  // should be ignored because it was swapped for ETH and then to either CORE or WBTC.
                  var three = existsThreeTransfers(toLGE);
                  print("Exists three CORE/WBTC transfers: $three");
                  if (!firstTime || !existsThreeTransfers(toLGE)) {
                    var coreHistoric =
                        await coreValueOfWBTC(amount, tx.blockNumber, l);
                    logprint(l,
                        "Historic value of WBTC in CORE: ${raw18(coreHistoric)}");
                    logprint(l,
                        "Transfer amount: ${raw8(amount)} ${symbolOfTokenTransfer(token)}");
                    logprint(l,
                        "* Adding units historic value ${raw18(coreHistoric)}");
                    units += coreHistoric;
                  } else {
                    firstTime = false;
                  }
                }
              } else if (depositToken == core.wbtcAddr) {
                // Either it is kept or swapped to CORE
                if (toLGE.length == 1) {
                  // WBTC kept
                  if (token == core.wbtcAddr) {
                    var coreHistoric =
                        await coreValueOfWBTC(amount, tx.blockNumber, l);
                    logprint(l,
                        "Historic value of WBTC in CORE: ${raw18(coreHistoric)}");
                    logprint(l,
                        "Transfer amount: ${raw8(amount)} ${symbolOfTokenTransfer(token)}");
                    logprint(l,
                        "* Adding units historic value ${raw18(coreHistoric)}");
                    units += coreHistoric;
                  } else {
                    throw "If WBTC was deposited and a single Transfer, it should be WBTC";
                  }
                }
              } else if (depositToken == core.coreAddr) {
                if (token == core.coreAddr) {
                  // CORE came in but we have already handled that up top!
                } else {
                  throw "If CORE was deposited no other Transfer should occur";
                }
              } else if (depositToken == core.wethAddr) {
                // This will get swapped to CORE or WBTC
                if (token == core.wbtcAddr) {
                  var coreHistoric =
                      await coreValueOfWBTC(amount, tx.blockNumber, l);
                  logprint(l,
                      "Historic value of WBTC in CORE: ${raw18(coreHistoric)}");
                  logprint(l,
                      "Transfer amount: ${raw8(amount)} ${symbolOfTokenTransfer(token)}");
                  logprint(l,
                      "* Adding units historic value ${raw18(coreHistoric)}");
                  units += coreHistoric;
                } else {
                  throw "If WETH was deposited it should be WBTC or CORE";
                }
              } else {
                throw "Unknown deposit token";
              }
            }
          }
          contrib.units = units;
          logprint(l, "* Total units ${raw18(units)}");
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
      // Calculate deviation of coreValue from the more correct units value, in percent rounded to two decimals.
      contrib.updateDeviation();
      await contrib.update();
      print("------------------------------------------------");
    }
    print("Done");
  }

  checkContract() async {
    // Loop through all Contributions and update Holder sum
    var sums = await Contribution.getSumOfUnitsPerSender();
    print("Holders to update: ${sums.length}");
    for (var list in sums) {
      // Calculate deviation of coreValue from the more correct units value, in percent rounded to two decimals.
      var holder = await Holder.findHolder(EthereumAddress.fromHex(list[0]));
      if (holder != null) {
        holder.units = list[1];
        if (holder.units == BigInt.zero) {
          //print("Hmmm");
          //var ss = await Contribution.getTest();
        }
        holder.contractUnits = await core.unitsContributed(holder.address);
        holder.updateDeviation();
        await holder.update();
        print("Updated ${holder.address.hex}");
      } else {
        print(
            "A new contribution that hasn't been processed yet - just ignore.");
      }
    }
    // Loop through Holders and query points in contract
  }
}
