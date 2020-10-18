import 'package:postgres/postgres.dart';
import 'package:robocore/core.dart';
import 'package:robocore/database.dart';
import 'package:web3dart/web3dart.dart';

const lge = 2;

//event CoreBought(uint256 COREamt, address from);
class CoreBought {
  late int id;
  late int lge;
  DateTime created = DateTime.now().toUtc();

  late BigInt coreAmt;
  late EthereumAddress sender; //from
  late String tx;

  CoreBought(this.id, this.lge, this.coreAmt, this.sender, this.tx);

  CoreBought.from(this.lge, ContractEvent ev, FilterEvent fe) {
    final decoded = ev.decodeResults(fe.topics, fe.data);
    tx = fe.transactionHash;
    coreAmt = decoded[0] as BigInt;
    sender = decoded[1] as EthereumAddress;
  }

  static Future<PostgreSQLResult> dropTable() async {
    return await db.query("drop table if exists _contribution;");
  }

  static Future<PostgreSQLResult> createTable() async {
    return await db.query(
        "create table IF NOT EXISTS _corebought (id integer GENERATED ALWAYS AS IDENTITY, PRIMARY KEY(id), lge integer, created timestamp, sender text, tx text, coreAmt numeric);");
  }

  Future<void> save() async {
    await db.query(
        "INSERT INTO _corebought (lge, created, sender, tx, coreAmt) VALUES (@lge, @created, @sender, @tx, @coreAmt)",
        substitutionValues: {
          "lge": lge,
          "created": created.toIso8601String(),
          "sender": sender.hex,
          "tx": tx,
          "coreAmt": coreAmt.toString(),
        });
  }

  static Future<List<List>> getAll() async {
    List<List<dynamic>> results = await db.query("SELECT * FROM _corebought");
    return results;
  }

  static Future<BigInt> getTotalSum() async {
    List<List<dynamic>> results =
        await db.query("select sum(coreamt) from \"_corebought\"");
    return numericToBigInt(results.first[0]);
  }

  static Future<BigInt> getSumLast(Duration duration) async {
    var now = DateTime.now().toUtc();
    List<List<dynamic>> results = await db.query(
        "select sum(coreamt) from \"_corebought\" where created > @marker;",
        substitutionValues: {"marker": now.subtract(duration)});
    return numericToBigInt(results.first[0]);
  }

  String makeMessage() {
    return "CORE bought ${dec4(raw18(coreAmt))} CORE from <https://etherscan.io/address/$sender>, txn: <https://etherscan.io/tx/$tx>";
  }
}
