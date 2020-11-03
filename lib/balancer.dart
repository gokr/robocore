import 'package:robocore/contract.dart';

import 'package:robocore/ethclient.dart';
import 'package:web3dart/credentials.dart';

class BalancerPool extends Contract {
  BalancerPool(EthClient client, addressHex)
      : super(client, 'Balancer.json', addressHex) {}

  BalancerPool.customAbi(EthClient client, String abi, String addressHex)
      : super(client, abi, addressHex) {}

  Future<BigInt> getSpotPrice(EthereumAddress tokenIn, tokenOut) async {
    final result = await callFunction('getSpotPrice', [tokenIn, tokenOut]);
    return result.first;
  }
}
