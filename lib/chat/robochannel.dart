import 'package:robocore/robocore.dart';
import 'package:robocore/robowrapper.dart';

abstract class RoboChannel {
  late int id;

  RoboChannel(this.id);

  RoboWrapper getWrapperFromBot(Robocore bot);

  bool operator ==(other);

  String toString();
}
