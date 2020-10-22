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
  int? holder;
  String log = "";

  Contribution(this.id, this.lge, this.created, this.sender, this.tx,
      this.coreValue, this.coin, this.units, this.holder, this.log);

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
        "create table IF NOT EXISTS _contribution (id integer GENERATED ALWAYS AS IDENTITY, PRIMARY KEY(id), lge integer, created timestamp, sender text, tx text, coreValue numeric, coin text, units numeric, holder int4, log text);");
  }

  Future<void> update() async {
    var result = await db.query(
        "UPDATE _contribution SET lge = @lge, created = @created, sender = @sender, tx = @tx, coreValue = @coreValue, coin = @coin, units = @units, holder = @holder, log = @log WHERE id = @id",
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
          "log": log
        });
    print(result);
  }

  Future<void> insert() async {
    var result = await db.query(
        "INSERT INTO _contribution (lge, created, sender, tx, coreValue, coin, units, holder, log) VALUES (@lge, @created, @sender, @tx, @coreValue, @coin, @units, @holder, @log)",
        substitutionValues: {
          "lge": lge,
          "created": created.toIso8601String(),
          "sender": sender.hex,
          "tx": tx,
          "coreValue": coreValue.toString(),
          "coin": coin,
          "units": units.toString(),
          "holder": holder,
          "log": log
        });
    print(result);
  }

  static Future<List<Contribution>> getAll() async {
    List<List<dynamic>> results = await db.query(
        "SELECT id, lge, created, sender, tx, coreValue, coin, units, holder, log FROM _contribution");
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
          list[9]);
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
