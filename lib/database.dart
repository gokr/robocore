import 'dart:typed_data';

import 'package:postgres/postgres.dart';

late PostgreSQLConnection db;

Future<PostgreSQLConnection> openDatabase(Map config) async {
  var pg = config['postgresql'];
  db = PostgreSQLConnection(pg['host'], pg['port'], pg['databaseName'],
      username: pg['username'], password: pg['password']);
  await db.open();
  return db;
}

/// numeric:
///    A variable-length numeric value, can be negative.
///    text: NaN or first - if it is negative, then the digits with . as decimal separator
///    binary:
///        first a header of 4 16-bit signed integers:
///            number of digits in the digits array that follows (can be 0, but not negative),
///            weight of the first digit (10000^weight), can be both negative, positive or 0,
///            sign: negative=0x4000, positive=0x0000, NaN=0xC000
///            dscale: number of digits (in base 10) to print after the decimal separator
///        then the array of digits:
///            The digits are stored in base 10000, where each digit is a 16-bit integer.
///            Trailing zeros are not stored in this array, to save space.
///            The digits are stored such that, if written as base 10000, the decimal separator can be inserted between two digits in base 10000,
///                i.e. when this is to be printed in base 10, only the first digit in base 10000 can (possibly) be printed with less than 4 characters.
///                Note that this does not apply for the digits after the decimal separator; the digits should be printed out in chunks of 4
///                characters and then truncated with the given dscale.
BigInt numericToBigInt(dynamic d) {
  Uint8List data;
  // Fix
  if (!(d is Uint8List)) {
    if (d == null) {
      return BigInt.zero;
    }
    data = Uint8List.fromList(d.codeUnits);
  } else {
    data = d;
  }
  if (data == null) return BigInt.zero;
  int digits = data[0] * 256 + data[1];
  int weight = data[2] * 256 + data[3];
  bool negative = data[4] == 0x40;
  // dscale ignored right now
  var result = BigInt.zero;
  for (int i = 0; i < digits; i++) {
    int pos = i * 2 + 8;
    result += BigInt.from(data[pos] * 256 + data[pos + 1]) *
        BigInt.from(10000).pow(weight);
    weight -= 1;
  }
  return negative ? -result : result;
}
