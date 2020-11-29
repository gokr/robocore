import 'dart:math';

import 'package:intl/intl.dart';
import 'package:markdown/markdown.dart';

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

// For Telegram
String makeHearts(num eth, int limit) {
  return makeRepeatedString(eth.round(), "💚", limit);
}

// For Discord
String makeHappies(num core, int limit) {
  var char = ["🦕", "🐉", "💚", "🍀", "🍏", "✅"].pickRandom();
  return makeRepeatedString(core.round(), char, limit);
}

extension Markdown on String {
  /// Hacked Telegram halfass Markdown
  String markdownToHTML() {
    var html = markdownToHtml(this);
    html = html.replaceAll('<p>', '');
    html = html.replaceAll('</p>', '');
    return html;
  }
}

extension RandomPick on List<String> {
  String pickRandom() {
    var rand = Random().nextInt(this.length);
    return this[rand];
  }
}

extension DiffList on List<num> {
  /// Return a new List where each element is subtracted from base.
  List<num> baseline(num base) {
    return map((each) => base - each).toList();
  }

  /// Return a new List where each element is delta from the previous.
  List<num> delta() {
    final List<num> result = [];
    num previous = 0;
    for (var each in this) {
      result.add(each - previous);
      previous = each;
    }
    return result;
  }

  /// Return a List of Lists containing value, delta, deltaPercent.
  List<List<num>> derived() {
    final List<List<num>> result = [];
    num previous = 0;
    for (var each in this) {
      var delta = each - previous;
      var percent = (delta / previous) * 100;
      result.add([each, delta, percent]);
      previous = each;
    }
    return result;
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

/// Note, this is x1e-5
num toCentimilli(num x) => x * 1e-5;

/// Note, this is x1e5
num centimilli(num x) => x * 1e5;

// Used powers of 10
final pow18 = BigInt.from(pow(10, 18));
final pow8 = BigInt.from(pow(10, 8));
final pow6 = BigInt.from(pow(10, 6));
final pow5 = BigInt.from(pow(10, 5));

/// From raw
num raw18(BigInt x) => (x / pow18).toDouble();
num raw8(BigInt x) => (x / pow8).toDouble();
num raw6(BigInt x) => (x / pow6).toDouble();
num raw5(BigInt x) => (x / pow5).toDouble();

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
