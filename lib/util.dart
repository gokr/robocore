import 'dart:math';

import 'package:intl/intl.dart';

String makeRepeatedString(int n, String str, int maxLength) {
  var buf = StringBuffer();
  int mx = max(min(n, (maxLength / str.length).truncate()), 1);
  for (int i = 0; i < mx; i++) {
    buf.write(str);
  }
  if (mx < n) {
    buf.write("...");
  }
  return buf.toString();
}

extension RandomPick on List<String> {
  String pickRandom() {
    var rand = Random().nextInt(this.length);
    return this[rand];
  }
}

// Hacky, but ok
String trimQuotes(String s) {
  var trimmed = s;
  if (s.startsWith("'")) {
    trimmed = s.substring(1);
  }
  if (trimmed.endsWith("'")) {
    return trimmed.substring(0, trimmed.length - 1);
  }
  return trimmed;
}

// Formatting stuff
NumberFormat decimal6Formatter = NumberFormat("##0.00000#");
NumberFormat decimal4Formatter = NumberFormat("##0.000#");
NumberFormat decimal2Formatter = NumberFormat("##0.0#");
NumberFormat decimal0Formatter = NumberFormat("###");
NumberFormat dollar0Formatter =
    NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 0);
NumberFormat dollar2Formatter =
    NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 2);
String dec6(num x) => decimal6Formatter.format(x);
String dec4(num x) => decimal4Formatter.format(x);
String dec2(num x) => decimal2Formatter.format(x);
String dec0(num x) => decimal0Formatter.format(x);
String usd0(num x) => dollar0Formatter.format(x);
String usd2(num x) => dollar2Formatter.format(x);
