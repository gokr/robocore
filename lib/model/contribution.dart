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

  late BigInt coreValue;
  late EthereumAddress sender;
  late String tx;

  Contribution(this.id, this.lge, this.coreValue, this.sender, this.tx);

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
        "create table IF NOT EXISTS _contribution (id integer GENERATED ALWAYS AS IDENTITY, PRIMARY KEY(id), lge integer, created timestamp, sender text, tx text, coreValue numeric);");
  }

  Future<void> save() async {
    await db.query(
        "INSERT INTO _contribution (lge, created, sender, tx, coreValue) VALUES (@lge, @created, @sender, @tx, @coreValue)",
        substitutionValues: {
          "lge": lge,
          "created": created.toIso8601String(),
          "sender": sender.hex,
          "tx": tx,
          "coreValue": coreValue.toString(),
        });
  }

  static Future<List<List>> getAll() async {
    List<List<dynamic>> results = await db.query("SELECT * FROM _contribution");
    return results;
  }

  static Future<BigInt> getSumLast(Duration duration) async {
    var now = DateTime.now().toUtc();
    List<List<dynamic>> results = await db.query(
        "select sum(corevalue) from \"_contribution\" where created > @marker;",
        substitutionValues: {"marker": now.subtract(duration)});
    return numericToBigInt(results.first[0]);
  }

  String makeMessage() {
    return "Contribution ${dec4(raw18(coreValue))} CORE from <https://etherscan.io/address/$sender>, txn: <https://etherscan.io/tx/$tx>";
  }
}
