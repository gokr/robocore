import 'package:postgres/postgres.dart';
import 'package:robocore/database.dart';
import 'package:robocore/pair.dart';
import 'package:robocore/util.dart';
import 'package:web3dart/web3dart.dart';

class Swap {
  late int id;
  late Pair pair;
  DateTime created = DateTime.now().toUtc();

  late BigInt amount0In, amount1In, amount0Out, amount1Out;
  late EthereumAddress sender;
  late EthereumAddress to;
  late String tx;

  /// If this was a sell of CORE
  late bool sell;

  /// If this was a buy of CORE
  bool get buy => !sell;

  // The swap amount in ETH
  BigInt get amount => sell ? amount1Out : amount1In;

  // The swap amount in token1
  BigInt get amount1 => sell ? amount0In : amount0Out;

  Swap(this.id, this.pair, this.amount0In, this.amount0Out, this.amount1In,
      this.amount1Out, this.sender, this.to, this.tx, this.sell);

  Swap.from(ContractEvent ev, FilterEvent fe, Pair p) {
    pair = p;
    final decoded = ev.decodeResults(fe.topics, fe.data);
    tx = fe.transactionHash;
    sender = decoded[0] as EthereumAddress;
    amount0In = decoded[1] as BigInt;
    amount1In = decoded[2] as BigInt;
    amount0Out = decoded[3] as BigInt;
    amount1Out = decoded[4] as BigInt;
    to = decoded[5] as EthereumAddress;
    sell = amount0In > BigInt.zero;
  }

  static Future<PostgreSQLResult> dropTable() async {
    return await db.query("drop table if exists _swap;");
  }

  static Future<PostgreSQLResult> createTable() async {
    return await db.query(
        "create table IF NOT EXISTS _swap (swap_id integer GENERATED ALWAYS AS IDENTITY, PRIMARY KEY(swap_id), pair integer, created timestamp, sender text, _to text, tx text, sell boolean, amount0In numeric, amount0Out numeric, amount1In numeric, amount1Out numeric, amount numeric);");
  }

  Future<void> save() async {
    await db.query(
        "INSERT INTO _swap (pair, created, sender, _to, tx, sell, amount0In, amount0Out, amount1In, amount1Out, amount) VALUES (@pair, @created, @sender, @to, @tx, @sell, @amount0In, @amount0Out, @amount1In, @amount1Out, @amount)",
        substitutionValues: {
          "pair": pair.id,
          "created": created.toIso8601String(),
          "sender": sender.hex,
          "to": to.hex,
          "tx": tx,
          "sell": sell,
          "amount0In": amount0In.toString(),
          "amount0Out": amount0Out.toString(),
          "amount1In": amount1In.toString(),
          "amount1Out": amount1Out.toString(),
          "amount": amount.toString(),
        });
  }

  static Future<List<List>> getAll() async {
    List<List<dynamic>> results = await db.query("SELECT * FROM _swap");
    return results;
  }

  String makeMessage() {
    if (sell) {
      // Swapped CORE->ETH
      return "Sold ${dec4(raw18(amount0In))} CORE for ${dec4(raw18(amount1Out))} ETH to <https://etherscan.io/address/$to>, txn: <https://etherscan.io/tx/$tx>";
    } else {
      // Swapped ETH->CORE
      return "Bought ${dec4(raw18(amount0Out))} CORE for ${dec4(raw18(amount1In))} ETH ->   to <https://etherscan.io/address/$to>, txn: <https://etherscan.io/tx/$tx>";
    }
  }
}
