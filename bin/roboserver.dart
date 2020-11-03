import 'package:robocore/roboserver.dart';
import 'package:robocore/config.dart';

main(List<String> arguments) async {
  Map config = loadConfig();
  log.info("Starting Roboserver");
  var server = Roboserver.config(config);
  // await bot.test();
  await server.start();
}
