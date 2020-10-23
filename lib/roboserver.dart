import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:robocore/core.dart';
import 'package:robocore/model/contribution.dart';
import 'package:robocore/model/corebought.dart';
import 'package:robocore/model/swap.dart';
import 'package:robocore/model/poster.dart';

import 'database.dart';

Logger log = Logger("Roboserver");

/// Server
class Roboserver {
  late Map config;

  /// To interact with Ethereum contracts
  late Core core;

  /// Subscription for Ethereum events
  late StreamSubscription subscription;

  Roboserver(this.config);

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
    core = Core.randomKey(config['apiurl'], config['wsurl']);
    await core.readContracts();

    // We listen to all Swaps on COREETH
    subscription = core.listenToEvent(core.CORE2ETH, 'Swap', (ev, event) {
      //print("Topics: ${event.topics} data: ${event.data}");
      var swap = Swap.from(ev, event);
      swap.save();
    });

    // We listen to all Contributions on LGE2
    subscription = core.listenToEvent(core.LGE2, 'Contibution', (ev, event) {
      //print("Topics: ${event.topics} data: ${event.data}");
      var contrib = Contribution.from(2, ev, event);
      contrib.insert();
    });

    // We listen to all Contributions on LGE2
    subscription = core.listenToEvent(core.LGE2, 'COREBought', (ev, event) {
      //print("Topics: ${event.topics} data: ${event.data}");
      var cb = CoreBought.from(2, ev, event);
      cb.save();
    });
  }
}
