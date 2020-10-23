import 'package:postgres/postgres.dart';
import 'package:robocore/core.dart';
import 'package:robocore/database.dart';
import 'package:web3dart/web3dart.dart';

const lge = 2;

//event Contribution(uint256 COREvalue, address from);
class Contribution {
  late int id;
  late int lge;
  DateTime created = DateTime.now().toUtc();

  BigInt coreValue = BigInt.zero;
  late EthereumAddress sender;
  late String tx;

  late String coin;
  BigInt units = BigInt.zero;
  double deviation = 0;
  int? holder;
  String log = "";

  updateDeviation() {
    if (coreValue > BigInt.zero) {
      var diff = units - coreValue;
      deviation = ((10000 * (diff / units)).roundToDouble() / 100).abs();
      if (!deviation.isFinite) deviation = 0;
    } else {
      deviation = 0;
    }
  }

  Contribution(
      this.id,
      this.lge,
      this.created,
      this.sender,
      this.tx,
      this.coreValue,
      this.coin,
      this.units,
      this.holder,
      this.log,
      this.deviation);

  Contribution.from(this.lge, ContractEvent ev, FilterEvent fe) {
    final decoded = ev.decodeResults(fe.topics, fe.data);
    tx = fe.transactionHash;
    coreValue = decoded[0] as BigInt;
    sender = decoded[1] as EthereumAddress;
  }

  static Future<PostgreSQLResult> dropTable() async {
    return await db.query("drop table if exists _contribution;");
  }

  static Future<PostgreSQLResult> createTable() async {
    return await db.query(
        "create table IF NOT EXISTS _contribution (id integer GENERATED ALWAYS AS IDENTITY, PRIMARY KEY(id), lge integer, created timestamp, sender text, tx text, coreValue numeric, coin text, units numeric, deviation double, holder int4, log text);");
  }

  Future<void> update() async {
    var result = await db.query(
        "UPDATE _contribution SET lge = @lge, created = @created, sender = @sender, tx = @tx, coreValue = @coreValue, coin = @coin, units = @units, holder = @holder, log = @log, deviation = @deviation WHERE id = @id",
        substitutionValues: {
          "id": id,
          "lge": lge,
          "created": created.toIso8601String(),
          "sender": sender.hex,
          "tx": tx,
          "coreValue": coreValue.toString(),
          "coin": coin,
          "units": units.toString(),
          "holder": holder,
          "log": log,
          "deviation": deviation
        });
    print(result);
  }

  Future<void> insert() async {
    var result = await db.query(
        "INSERT INTO _contribution (lge, created, sender, tx, coreValue, coin, units, holder, log, deviation) VALUES (@lge, @created, @sender, @tx, @coreValue, @coin, @units, @holder, @log, @deviation)",
        substitutionValues: {
          "lge": lge,
          "created": created.toIso8601String(),
          "sender": sender.hex,
          "tx": tx,
          "coreValue": coreValue.toString(),
          "coin": coin,
          "units": units.toString(),
          "holder": holder,
          "log": log,
          "deviation": deviation
        });
    print(result);
  }

  static Future<List<Contribution>> getAll() async {
    List<List<dynamic>> results = await db.query(
        "SELECT id, lge, created, sender, tx, coreValue, coin, units, holder, log, deviation FROM _contribution");
    return fromResults(results);
  }

  static Future<List<Contribution>> getUnprocessed() async {
    List<List<dynamic>> results = await db.query(
        "SELECT id, lge, created, sender, tx, coreValue, coin, units, holder, log, deviation FROM _contribution where coin is null");
    return fromResults(results);
  }

  static List<Contribution> fromResults(List<List<dynamic>> results) {
    return results.map((list) {
      return Contribution(
          list[0],
          list[1],
          list[2],
          EthereumAddress.fromHex(list[3]),
          list[4],
          numericToBigInt(list[5]),
          list[6],
          numericToBigInt(list[7]),
          list[8],
          list[9],
          list[10]?.toDouble() ?? 0);
    }).toList();
  }

  static Future<List> getSumOfUnitsPerSender() async {
    var results = await db.query(
        "select sender, sum(units) from \"_contribution\" group by sender;");
    return results.map((list) {
      return [list[0], numericToBigInt(list[1])];
    }).toList();
  }

  static Future<BigInt> getSumLast(Duration duration) async {
    var now = DateTime.now().toUtc();
    List<List<dynamic>> results = await db.query(
        "select sum(corevalue) from \"_contribution\" where created > @marker;",
        substitutionValues: {"marker": now.subtract(duration)});
    var res = results.first[0];
    if (res is String) {
      return BigInt.zero;
    }
    return numericToBigInt(results.first[0]);
  }

  String makeMessage() {
    return "Contribution ${dec4(raw18(coreValue))} CORE from <https://etherscan.io/address/$sender>, txn: <https://etherscan.io/tx/$tx>";
  }
}
