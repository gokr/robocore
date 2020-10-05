import 'package:robocore/core.dart';
import "package:test/test.dart";

void main() {
  test("silly math", () {
    var raw = BigInt.parse('3759052940941028200680');
    expect(raw2real(raw), equals(3759.052940941028));
    expect(coreFormatter.format(raw2real(raw)), equals("3759.0529"));
  });
}
