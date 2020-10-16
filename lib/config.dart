import 'package:logging/logging.dart';
import 'package:yaml/yaml.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

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
      // Do some base stuff
      String logLevel = config['loglevel'];
      var level =
          Level.LEVELS.firstWhere((l) => l.name.toLowerCase() == logLevel);
      Logger.root.level = level;
      print('Using logger level $level');
      Logger.root.onRecord.listen((LogRecord rec) {
        print(
            "[${rec.time}] [${rec.level.name}] [${rec.loggerName}] ${rec.message}");
      });
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
