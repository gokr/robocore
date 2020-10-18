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

final pow16 = BigInt.from(10000000000000000);
final pow12 = BigInt.from(1000000000000);
final pow8 = BigInt.from(100000000);
final pow4 = BigInt.from(10000);

BigInt numericToBigInt(Uint8List data) {
  if (data == null) return BigInt.zero;
  var result = BigInt.from(data[16] * 256 + data[17]) +
      BigInt.from(data[14] * 256 + data[15]) * pow4 +
      BigInt.from(data[12] * 256 + data[13]) * pow8 +
      BigInt.from(data[10] * 256 + data[11]) * pow12 +
      BigInt.from(data[8] * 256 + data[9]) * pow16;
  return result;
}

/*[0, 5,   0, 4,   0, 0,   0, 0,   0, 53, 35, 242, 2, 52, 37, 171, 16, 60]

number of digits: 5
weifht of first digit 10000^4
sign 0 = positive (40,0 = negative)
dscale 0

0, 53,   35, 242,   2, 52,   37, 171,   16, 60

(16*256+60) + (37*256+171) *10000 + (52+2*256)*100000000 + (242+35*256)*1000000000000 + 53 * 10 000 000 000 000 000

539202056496434156

18 bytes

numeric:
    A variable-length numeric value, can be negative.
    text: NaN or first - if it is negative, then the digits with . as decimal separator
    binary:
        first a header of 4 16-bit signed integers:
            number of digits in the digits array that follows (can be 0, but not negative),
            weight of the first digit (10000^weight), can be both negative, positive or 0,
            sign: negative=0x4000, positive=0x0000, NaN=0xC000
            dscale: number of digits (in base 10) to print after the decimal separator
        then the array of digits:
            The digits are stored in base 10000, where each digit is a 16-bit integer.
            Trailing zeros are not stored in this array, to save space.
            The digits are stored such that, if written as base 10000, the decimal separator can be inserted between two digits in base 10000,
                i.e. when this is to be printed in base 10, only the first digit in base 10000 can (possibly) be printed with less than 4 characters.
                Note that this does not apply for the digits after the decimal separator; the digits should be printed out in chunks of 4
                characters and then truncated with the given dscale.
                */
