import 'package:robocore/core.dart';
import 'package:web3dart/web3dart.dart';

class Swap {
  late BigInt amount0In, amount1In, amount0Out, amount1Out;
  late EthereumAddress sender, to;
  late String tx;

  /// If this was a sell of CORE
  late bool sell;

  /// If this was a buy of CORE
  bool get buy => !sell;

  // The swap amount in ETH
  BigInt get amount => sell ? amount1Out : amount1In;

  Swap.from(ContractEvent ev, FilterEvent fe) {
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

  void save() {}

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
