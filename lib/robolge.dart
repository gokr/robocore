import 'dart:io';

import 'package:logging/logging.dart';
import 'package:robocore/core.dart';
import 'package:robocore/etherscan.dart';
import 'package:robocore/model/contribution.dart';
import 'package:robocore/model/corebought.dart';
import 'package:robocore/model/holder.dart';
import 'package:robocore/model/swap.dart';
import 'package:robocore/poster.dart';
import 'package:web3dart/web3dart.dart';

import 'database.dart';

Logger log = Logger("Roboserver");

/// Server
class RoboLGE {
  late Map config;

  /// To interact with Ethereum contracts
  late Core core;

  late Etherscan scan;

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

    // Create our interface with Ethereum
    core = Core.randomKey(config['apiurl'], config['wsurl']);
    await core.readContracts();
  }

  recreateHistory() async {
    var contribs = await Contribution.getAll();
    for (var contrib in contribs) {
      var holder = await Holder.findOrCreateHolder(contrib);
      // If holder is not mapped yet, we do it
      if (contrib.holder == null) {
        contrib.holder = holder.id;
        contrib.update();
      }
      // CORE, ETH, WETH, WBTC, WBTC/ETH LP
      // coreValue is set when it was ETH, WETH or WBTC/ETH LP (part of which is ETH)
      var tx = await core.ethClient.getTransactionByHash(contrib.tx);
      var rc = await core.ethClient.getTransactionReceipt(contrib.tx);
      var logs = rc.logs;

      /* await core.ethClient.getLogs(FilterOptions(
          fromBlock: tx.blockNumber,
          toBlock: tx.blockNumber,
          address: core.LGE2Addr));*/
      print(
          "Corevalue: ${contrib.coreValue}"); // Is this when CORE was bought? In other words for ETH/WETH (and WBTC+ETHLP breaks into WBTC and ETH)
      print("To: ${tx.to}");
      print("Value: ${tx.value}");

      print("------------------------------------------------");

      // We need to look up txn and find coin and price
      //await Future.delayed(Duration(milliseconds: 100));
      //var tx = await scan.txlistinternal(contrib.tx);

      /*
      var ins = tx.
      if (ins.length > 1) {
        print("MORE THAN ONE");
        print(tx);
      }
      if (ins.isEmpty) {
        print("NO TRANSACTION: ${contrib.tx}");
      } else {
        var val = ins.first['value'];
        print("Tx: ${contrib.tx}, value: $val coreValue: ${contrib.coreValue}");
        print(tx);
        print("------------------------------------------------");
        //var tx2 = await scan.ethGetTransactionByHash(contrib.tx);
        //print(tx2);
      }*/
    }
    print("Done");
  }

  checkContract() async {}
}
