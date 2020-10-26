import 'package:robocore/chat/robochannel.dart';
import 'package:robocore/pair.dart';
import 'package:robocore/robocore.dart';
import 'package:robocore/model/swap.dart';

class EventLogger {
  late String name;
  Pair pair;
  RoboChannel channel;

  EventLogger(this.name, this.pair, this.channel);

  log(Robocore bot, Swap swap) async {}

  String toString() => name;
}
