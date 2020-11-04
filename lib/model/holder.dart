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
  late BigInt contractUnits = BigInt.zero;
  double deviation = 0;

  updateDeviation() {
    var diff = units - contractUnits;
    deviation = ((10000 * (diff / units)).roundToDouble() / 100).abs();
    if (!deviation.isFinite) deviation = 0;
  }

  Holder(this.id, this.lge, this.created, this.address, this.units,
      this.contractUnits, this.deviation);

  Holder.from(this.address, this.created) {
    lge = 2;
  }

  static Future<PostgreSQLResult> dropTable() async {
    return await db.query("drop table if exists _holder;");
  }

  static Future<PostgreSQLResult> createTable() async {
    return await db.query(
        "create table IF NOT EXISTS _holder (id integer GENERATED ALWAYS AS IDENTITY, PRIMARY KEY(id), lge integer, created timestamp, address text, units numeric, contractUnits numeric, deviation double);");
  }

  Future<void> update() async {
    var result = await db.query(
        "UPDATE _holder set lge = @lge, created = @created, address = @address, units = @units, contractUnits = @contractUnits, deviation = @deviation where id = @id",
        substitutionValues: {
          "id": id,
          "lge": lge,
          "created": created.toIso8601String(),
          "address": address.hex,
          "units": units.toString(),
          "contractUnits": contractUnits.toString(),
          "deviation": deviation
        });
    print(result);
  }

  Future<void> insert() async {
    await db.query(
        "INSERT INTO _holder (lge, created, address, units, contractUnits, deviation) VALUES (@lge, @created, @address, @units, @contractUnits, @deviation)",
        substitutionValues: {
          "lge": lge,
          "created": created.toIso8601String(),
          "address": address.hex,
          "units": units.toString(),
          "contractUnits": contractUnits.toString(),
          "deviation": deviation
        });
  }

  static Future<Holder?> findHolder(EthereumAddress address) async {
    List<List<dynamic>> results = await db.query(
        "SELECT id, lge, created, address, units, contractUnits, deviation  FROM _holder where address = @address",
        substitutionValues: {"address": address.hex});
    if (results.isNotEmpty) {
      var list = results.first;
      return Holder(list[0], list[1], list[2], EthereumAddress.fromHex(list[3]),
          numericToBigInt(list[4]), numericToBigInt(list[5]), list[6]);
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
    List<List<dynamic>> results = await db.query(
        "SELECT id, lge, created, address, units, contractUnits  FROM _holder");
    return results.map((list) {
      return Holder(list[0], list[1], list[2], EthereumAddress.fromHex(list[3]),
          numericToBigInt(list[4]), numericToBigInt(list[5]), list[6]);
    }).toList();
  }
}
