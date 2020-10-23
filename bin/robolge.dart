import 'dart:io';

import 'package:robocore/robolge.dart';
import 'package:robocore/config.dart';

main(List<String> arguments) async {
  Map config = loadConfig();
  var robo = RoboLGE(config);
  await robo.start();
  await robo.recreateHistory(true);
  await robo.checkContract();
  exit(0);
}
