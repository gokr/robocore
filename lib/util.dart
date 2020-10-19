String makeRepeatedString(int n, String str) {
  var buf = StringBuffer();
  for (int i = 1; i < n; i++) {
    buf.write(str);
  }
  return buf.toString();
}
