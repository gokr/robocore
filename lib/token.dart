import 'package:robocore/contract.dart';

import 'package:robocore/ethclient.dart';
import 'package:web3dart/web3dart.dart';

class Token extends Contract {
  Token(EthClient client, String addressHex)
      : super(client, 'IERC20.json', addressHex) {}

  Token.customAbi(EthClient client, String abi, String addressHex)
      : super(client, abi, addressHex) {}

  Future<BigInt> balanceOf(EthereumAddress address) async {
    final result = await callFunction('balanceOf', [address]);
    return result.first;
  }
}
