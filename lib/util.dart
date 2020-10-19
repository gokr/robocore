import 'dart:math';

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
