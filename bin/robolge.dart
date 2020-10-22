import 'dart:io';

import 'package:robocore/robolge.dart';
import 'package:robocore/config.dart';

main(List<String> arguments) async {
  Map config = loadConfig();
  var robo = RoboLGE(config);
  await robo.start();
  //if (arguments[0] == "recreate") {
  await robo.recreateHistory();
  await robo.checkContract();
  //} else if (arguments[0] == "check") {
  //  robo.checkContract();
  //}
  exit(0);
}
