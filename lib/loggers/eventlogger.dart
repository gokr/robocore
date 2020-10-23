import 'dart:math';

import 'package:nyxx/nyxx.dart';
import 'package:robocore/command.dart';
import 'package:robocore/core.dart';
import 'package:robocore/robocore.dart';
import 'package:robocore/model/swap.dart';
import 'package:robocore/util.dart';

class EventLogger {
  late String name;
  RoboChannel channel;

  EventLogger(this.name, this.channel);

  log(Robocore bot, Swap swap) async {}

  String toString() => name;
}
