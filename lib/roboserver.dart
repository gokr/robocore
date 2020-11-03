import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:robocore/ethclient.dart';
import 'package:robocore/model/contribution.dart';
import 'package:robocore/model/corebought.dart';
import 'package:robocore/ethereum.dart';
import 'package:robocore/model/swap.dart';
import 'package:robocore/model/poster.dart';

import 'database.dart';

Logger log = Logger("Roboserver");

// We keep a damn global just because it's easy
late Roboserver bot;

/// Server
class Roboserver {
  late Map config;

  /// To interact with Ethereum contracts
  late EthClient ethClient;

  /// Subscription for Ethereum events
  late StreamSubscription subscription;

  Roboserver(this.config);

  factory Roboserver.config(Map config) {
    bot = Roboserver(config);
    return bot;
  }

  start() async {
    await openDatabase(config);
    log.info("Postgres opened: ${db.databaseName}");

    try {
      await Swap.createTable();
      await Contribution.createTable();
      await CoreBought.createTable();
      await Poster.createTable();
      log.info("Created tables");
    } catch (e) {
      log.warning(e);
      exit(1);
    }

    // Create our interface with Ethereum
    ethClient = EthClient.randomKey(config['apiurl'], config['wsurl']);
    await ethClient.initialize();

    // Create our Ethereum world
    await Ethereum(ethClient).initialize();

    // We listen to all Swaps on COREETH
    subscription = ethereum.CORE2ETH.listenToEvent('Swap', (ev, event) {
      //print("Topics: ${event.topics} data: ${event.data}");
      var swap = Swap.from(ev, event, ethereum.CORE2ETH);
      swap.save();
    });

    // We listen to all Swaps on CORE2CBTC
    subscription = ethereum.CORE2CBTC.listenToEvent('Swap', (ev, event) {
      //print("Topics: ${event.topics} data: ${event.data}");
      var swap = Swap.from(ev, event, ethereum.CORE2CBTC);
      swap.save();
    });

    /*
    // We listen to all Contributions on LGE2
    subscription =
        ethClient.listenToEvent(ethClient.LGE2, 'Contibution', (ev, event) {
      //print("Topics: ${event.topics} data: ${event.data}");
      var contrib = Contribution.from(2, ev, event);
      contrib.insert();
    });

    // We listen to all COREBought on LGE2
    subscription =
        ethClient.listenToEvent(ethClient.LGE2, 'COREBought', (ev, event) {
      //print("Topics: ${event.topics} data: ${event.data}");
      var cb = CoreBought.from(2, ev, event);
      cb.save();
    });
    */
  }
}
