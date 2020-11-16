import 'dart:math';

import 'package:graphql/client.dart';
import 'package:robocore/balancer.dart';
import 'package:robocore/blocklytics.dart';
import 'package:robocore/contract.dart';

import 'package:robocore/ethclient.dart';
import 'package:robocore/ethereum.dart';
import 'package:robocore/uniswap.dart';
import 'package:robocore/util.dart';
import 'package:web3dart/web3dart.dart';

class Entity {
  late String label;
  late Function format;
  late String name;

  Entity(this.name, this.label, this.format);

  String toString() => name;
}

class Pair extends Contract {
  int id;
  String name;
  // Best would be to have both Tokens here too
  //Token t1;
  //Token t2;
  // We can pull these from ERC20Detailed.json later
  late String token1name, token2name;

  late int _decimals1;
  late BigInt pow1;
  late int _decimals2;
  late BigInt pow2;
  late int _decimalsLP;
  late BigInt powLP;

  set decimals1(int x) {
    _decimals1 = x;
    pow1 = BigInt.from(pow(10, _decimals1));
  }

  set decimals2(int x) {
    _decimals2 = x;
    pow2 = BigInt.from(pow(10, _decimals2));
  }

  set decimalsLP(int x) {
    _decimalsLP = x;
    powLP = BigInt.from(pow(10, _decimalsLP));
  }

  // These are all calculated when update() is called
  late num pool1, pool2, poolK;
  late num price1, price2, valueLP, priceLP;
  late num supplyLP;

  // Stats indexed by x hours ago
  Map<num, Map> stats = {};

  BalancerPool? balancer;

  num get liquidity => pool2 * 2;

  List<Entity> entities = [];

  Pair(this.id, EthClient client, this.name, String addressHex)
      : super(client, 'UniswapPair.json', addressHex) {
    decimals1 = 18;
    decimals2 = 18;
    decimalsLP = 18;
  }

  initialize() async {
    await super.initialize();
    initializeEntities();
    await update();
  }

  initializeEntities() {
    entities
      ..add(Entity("reserve0", "Reserve 0", (d) => dec2(d)))
      ..add(Entity("reserve1", "Reserve 1", (d) => dec2(d)))
      ..add(Entity("totalSupply", "Supply", (d) => dec2(d)))
      ..add(Entity("token0Price", "Token 0 price", (d) => dec2(d)))
      ..add(Entity("token1Price", "Token 1 price", (d) => dec2(d)))
      ..add(Entity("volumeToken0", "Volume token 0", (d) => dec2(d)))
      ..add(Entity("volumeToken1", "Volume token 1", (d) => dec2(d)))
      ..add(Entity("volumeUSD", "Volume USD", (d) => usd0(d)))
      ..add(Entity(
          "txCount", "Txn count", (d) => "${(d.isFinite) ? d.truncate() : d}"));
  }

  bool operator ==(o) => o is Pair && name == o.name;

  int get hashCode => name.hashCode;

  Entity? findEntity(String name) {
    for (var e in entities) {
      if (e.name.toLowerCase() == name) return e;
    }
    return null;
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
    return (amount / pow2).toDouble();
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

    // Value of LP is calculated as the full pool valuated in Token2, divided by supply
    valueLP = ((pool1 * price1) + pool2) / supplyLP;

    // Also pick out current balancer spot price in ETH
    if (balancer != null) {
      var eth = await balancer?.getSpotPrice(ethereum.WETH.address, address)
          as BigInt;
      priceLP = raw18(eth);
    }
  }

  /// Load stats for this pair at intervals ago, like [1,6,24,48] being
  /// 1h, 6h, 24h and 48h ago.
  fetchDefaultStats(List<num> intervals) async {
    stats = await fetchStats(intervals);
  }

  Future<Map<num, Map<dynamic, dynamic>>> fetchStats(
      List<num> intervals) async {
    Map<num, Map> newStats = {};
    for (var h in intervals) {
      var qr = (h == 0)
          ? await fetchLatestStats()
          : await fetchStatsAgo(Duration(seconds: (h * 3600).truncate()));
      if (qr == null || qr.data == null) {
        throw Exception("Failed to fetch stats ago $h");
      }
      newStats[h] = qr.data['pair'];
    }
    return newStats;
  }

  Future<QueryResult?> fetchLatestStats() async {
    /*var blk = await blocklytics.latestBlockNumber();
    print("Latest block: $blk");
    if (blk != null) {
      return await uniswap.pairStatsAtBlock(BlockNum.exact(blk), address);
    }
    return null;*/
    return await uniswap.pairStats(address);
  }

  Future<QueryResult?> fetchStatsAgo(Duration duration) async {
    var blk = await blocklytics.blockAgo(duration);
    print("Duration: $duration block: $blk");
    if (blk != null) {
      return await uniswap.pairStatsAtBlock(blk, address);
    }
    return null;
  }

  List<num> statsArray(List<num> keys, String entity) {
    return extractArray(stats, keys, entity);
  }

  /// Extract a given entity at keys from the statistics map.
  List<num> extractArray(Map<num, Map<dynamic, dynamic>> statistics,
      List<num> keys, String entity) {
    List<num> result = [];
    for (var h in keys) {
      var val = double.parse(statistics[h]?[entity]);
      result.add(val);
    }
    return result;
  }

  String priceString1([num amount = 1]) {
    return "$amount $token1name = ${dec4(price1 * amount)} $token2name";
  }

  String priceString2([num amount = 1]) {
    return "$amount $token2name = ${dec4(price2 * amount)} $token1name";
  }

  String toString() => name;
}
