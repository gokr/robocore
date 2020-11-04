import 'package:robocore/robocore.dart';
import 'package:robocore/config.dart';

main(List<String> arguments) async {
  Map config = loadConfig("robocore");
  log.info("Starting Robocore");
  var bot = Robocore(config);
  //await bot.test();
  await bot.start();
}
