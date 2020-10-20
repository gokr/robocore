import 'package:postgres/postgres.dart';
import 'package:robocore/database.dart';
import 'package:robocore/model/contribution.dart';
import 'package:web3dart/web3dart.dart';

const lge = 2;

class Holder {
  late int id;
  late int lge;
  DateTime created = DateTime.now().toUtc();

  late EthereumAddress address;
  late BigInt units = BigInt.zero;

  Holder(this.id, this.lge, this.created, this.address, this.units);

  Holder.from(this.address, this.created) {
    lge = 2;
  }

  static Future<PostgreSQLResult> dropTable() async {
    return await db.query("drop table if exists _holder;");
  }

  static Future<PostgreSQLResult> createTable() async {
    return await db.query(
        "create table IF NOT EXISTS _holder (id integer GENERATED ALWAYS AS IDENTITY, PRIMARY KEY(id), lge integer, created timestamp, address text, units numeric);");
  }

  Future<void> update() async {
    var result = await db.query(
        "UPDATE _holder set lge = @lge, set created = @created, set address = @address, set units = @units where id = @id",
        substitutionValues: {
          "id": id,
          "lge": lge,
          "created": created.toIso8601String(),
          "address": address.hex,
          "units": units.toString(),
        });
    print(result);
  }

  Future<void> insert() async {
    var result = await db.query(
        "INSERT INTO _holder (lge, created, address, units) VALUES (@lge, @created, @address, @units)",
        substitutionValues: {
          "lge": lge,
          "created": created.toIso8601String(),
          "address": address.hex,
          "units": units.toString(),
        });
    //print(result);
  }

  static Future<Holder?> findHolder(EthereumAddress address) async {
    List<List<dynamic>> results = await db.query(
        "SELECT id, lge, created, address, units  FROM _holder where address = @address",
        substitutionValues: {"address": address.hex});
    if (results.isNotEmpty) {
      var list = results.first;
      return Holder(list[0], list[1], list[2], EthereumAddress.fromHex(list[3]),
          numericToBigInt(list[4]));
    }
  }

  static Future<Holder> findOrCreateHolder(Contribution contrib) async {
    var address = contrib.sender;
    var timestamp = contrib.created;
    var holder = await findHolder(address);
    if (holder == null) {
      // Then we create one
      holder = Holder.from(address, timestamp);
      await holder.insert();
      // Reload to get id
      holder = await Holder.findHolder(holder.address);
    }
    return holder as Holder;
  }

  static Future<List<Holder>> getAll() async {
    List<List<dynamic>> results =
        await db.query("SELECT id, lge, created, address, units  FROM _holder");

    return results.map((list) {
      return Holder(list[0], list[1], list[2], EthereumAddress.fromHex(list[3]),
          numericToBigInt(list[4]));
    }).toList();
  }
}
