import 'package:robocore/roboserver.dart';
import 'package:robocore/config.dart';

main(List<String> arguments) async {
  Map config = loadConfig("roboserver");
  log.info("Starting Roboserver");
  var server = Roboserver(config);
  // await bot.test();
  await server.start();
}
