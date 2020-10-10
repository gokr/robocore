import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:logging/logging.dart';
import 'package:robocore/robocore.dart';
import 'package:yaml/yaml.dart';

const configFileName = 'robocore.yaml';

/// Load YAML configuration
dynamic loadConfig() {
  var home = Platform.environment['HOME'];
  var configPath = path.join(home, configFileName);
  var f = File(configPath);
  if (f.existsSync()) {
    try {
      var yamlContent = f.readAsStringSync();
      var config = loadYaml(yamlContent);
      print('Loaded configuration from $configPath');
      return config;
    } catch (e) {
      print('Failed to parse config file $configPath : $e');
      exit(1);
    }
  } else {
    print('Missing configuration file $configPath');
    exit(1);
  }
}

main(List<String> arguments) async {
  Map config = loadConfig();
  String logLevel = config['loglevel'];
  var level = Level.LEVELS.firstWhere((l) => l.name.toLowerCase() == logLevel);
  Logger.root.level = level;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.message}');
  });
  log.info("Starting Robocore with log level $logLevel");
  var bot = Robocore(config);
  // await bot.test();
  await bot.start();
}
