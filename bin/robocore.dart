import 'package:logging/logging.dart';
import 'package:robocore/discord.dart';

main(List<String> arguments) async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.message}');
  });
  log.info("Starting Robocore");
  var bot = Robocore();
  // await bot.test();
  await bot.start();
}
