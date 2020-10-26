import 'dart:math';

import 'package:robocore/contract.dart';

import 'package:robocore/ethclient.dart';

class Pair extends Contract {
  int id;
  String name;
  // Best would be to have both Tokens here too
  //Token t1;
  //Token t2;
  // We can pull these from ERC20Detailed.json later
  int decimals1 = 18;
  late BigInt pow1;
  int decimals2 = 18;
  late BigInt pow2;
  int decimalsLP = 18;
  late BigInt powLP;

  // These are all calculated when update() is called
  late num pool1, pool2, poolK;
  late num price1, price2, priceLP;
  late num supplyLP;

  num get liquidity => pool2 * 2;

  Pair(this.id, EthClient client, this.name, String addressHex)
      : super(client, 'UniswapPair.json', addressHex) {
    pow1 = BigInt.from(pow(10, decimals1));
    pow1 = BigInt.from(pow(10, decimals2));
    powLP = BigInt.from(pow(10, decimalsLP));
  }

  Future<List<dynamic>> getReserves() async {
    return await callFunction('getReserves');
  }

  Future<BigInt> totalSupply() async {
    final result = await callFunction('totalSupply');
    return result.first;
  }

  num raw1(BigInt amount) {
    return (amount / pow1).toDouble();
  }

  num raw2(BigInt amount) {
    return (amount / pow1).toDouble();
  }

  num rawLP(BigInt amount) {
    return (amount / powLP).toDouble();
  }

  update() async {
    var reserves = await getReserves();
    pool1 = raw1(reserves[0]);
    pool2 = raw2(reserves[1]);
    poolK = pool1 * pool2;
    price2 = pool1 / pool2;
    price1 = pool2 / pool1;

    // This is all LPs minted so far
    supplyLP = rawLP(await totalSupply());

    // Price of LP is calculated as the full pool valuated in Token2, divided by supply
    priceLP = ((pool1 * price1) + pool2) / supplyLP;
  }
}
