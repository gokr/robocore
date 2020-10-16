import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:robocore/core.dart';
import 'package:robocore/model/swap.dart';
import 'package:robocore/poster.dart';

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
      //await Poster.dropTable();
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
  }
}
