import 'package:robocore/balancer.dart';
import 'package:robocore/contract.dart';
import 'package:robocore/corevault.dart';
import 'package:robocore/ethclient.dart';
import 'package:robocore/fannyvault.dart';
import 'package:robocore/pair.dart';
import 'package:robocore/token.dart';

import 'config.dart';

late Ethereum ethereum;

/// Model of pairs, tokens, contracts
class Ethereum {
  EthClient client;

  late Token CORE, WBTC, WETH, DAI, FANNY, COREDAI, WCORE;

  Map<String, Pair> pairs = {};

  // CORE pairs
  late Pair CORE2ETH, CORE2CBTC, CORE2FANNY, COREDAI2WCORE;

  // Other pairs
  late Pair DAI2ETH, ETH2USDT, WBTC2ETH;
  //late Pair WBTC2USDT; No liquidity, can not be used

  DateTime? statsTimestamp = DateTime.now().subtract(Duration(minutes: 10));

  late Contract LGE2, LGE3, COREBURN, TRANSFERCHECKER;

  late CoreVault COREVAULT;
  late FannyVault FANNYVAULT;

  Ethereum(this.client) {
    ethereum = this;
  }

  initialize() async {
    // Contracts
    LGE2 = Contract(
        client, 'cLGE.json', '0xf7ca8f55c54cbb6d0965bc6d65c43adc500bc591');
    await LGE2.initialize();
    COREVAULT = CoreVault(client);
    await COREVAULT.initialize();

    LGE3 = Contract(client, 'CORE_LGE_3.json',
        '0xaac50b95fbb13956d7c45511f24c3bf9e2a4a76b');
    await LGE3.initialize();

    COREBURN = Contract(
        client, 'COREBurn.json', '0x0f199137f96EF9269897EDEF4157940a4d4AA475');
    await COREBURN.initialize();

    COREVAULT = CoreVault(client);
    await COREVAULT.initialize();

    FANNYVAULT = FannyVault(client);
    await FANNYVAULT.initialize();

    TRANSFERCHECKER = Contract(client, 'TransferChecker.json',
        '0x2e2A33CECA9aeF101d679ed058368ac994118E7a');
    await TRANSFERCHECKER.initialize();

    // Tokens
    CORE = Token.customAbi(
        client, 'CORE.json', '0x62359Ed7505Efc61FF1D56fEF82158CcaffA23D7');
    await CORE.initialize();
    WBTC = Token(client, '0x2260fac5e5542a773aa44fbcfedf7c193bc2c599');
    await WBTC.initialize();
    WETH = Token.customAbi(
        client, 'WETH.json', '0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2');
    await WETH.initialize();
    DAI = Token(client, '0x6b175474e89094c44da98b954eedeac495271d0f');
    await DAI.initialize();
    FANNY = Token(client, '0x8ad66f7e0e3e3dc331d3dbf2c662d7ae293c1fe0');
    await FANNY.initialize();

    // Uniswap pairs
    CORE2ETH = Pair(
        1, client, "core-eth", '0x32ce7e48debdccbfe0cd037cc89526e4382cb81b');
    var bal =
        BalancerPool(client, '0x30cb859317e171832b064c97cc03ccb081954d1b');
    await bal.initialize();
    CORE2ETH
      ..token1name = "CORE"
      ..token2name = "ETH"
      ..balancer = bal;
    await addPair(CORE2ETH);

    CORE2CBTC = Pair(
        2, client, "core-cbtc", '0x6fad7d44640c5cd0120deec0301e8cf850becb68');
    bal = BalancerPool(client, '0x5390f43ef8b8fe0b103e89f1ca74bfb985669f7b');
    await bal.initialize();
    CORE2CBTC
      ..decimals2 = 8
      ..token1name = "CORE"
      ..token2name = "CBTC"
      ..balancer = bal;
    await addPair(CORE2CBTC);

    CORE2FANNY = Pair(
        6, client, "core-fanny", '0x85d9DCCe9Ea06C2621795889Be650A8c3Ad844BB');
    //bal = BalancerPool(client, '0x85d9DCCe9Ea06C2621795889Be650A8c3Ad844BB');
    //await bal.initialize();
    CORE2FANNY
      ..token1name = "CORE"
      ..token2name = "FANNY";
    //  ..balancer = bal;
    await addPair(CORE2FANNY);

    COREDAI2WCORE = Pair(7, client, "coredai-wcore",
        '0x01ac08e821185b6d87e68c67f9dc79a8988688eb');
    bal = BalancerPool(client, '0xcf259c85e12adfcb98245867f5b75ce0aeb7382b');
    await bal.initialize();
    COREDAI2WCORE
      ..token1name = "coreDAI"
      ..token2name = "WCORE"
      ..balancer = bal;
    await addPair(COREDAI2WCORE);

    ETH2USDT = Pair(
        3, client, "eth-usdt", '0x0d4a11d5eeaac28ec3f61d100daf4d40471f1852');
    ETH2USDT
      ..decimals2 = 6
      ..token1name = "ETH"
      ..token2name = "USDT";
    await addPair(ETH2USDT);

    DAI2ETH = Pair(
        4, client, "dai-eth", '0xa478c2975ab1ea89e8196811f51a7b7ade33eb11');
    DAI2ETH
      ..token1name = "DAI"
      ..token2name = "ETH";
    await addPair(DAI2ETH);

    /*WBTC2USDT = Pair(
        4, client, "wbtc-usdt", '0x0de0fa91b6dbab8c8503aaa2d1dfa91a192cb149');
    WBTC2USDT
      ..decimals1 = 8
      ..decimals2 = 6
      ..token1name = "WBTC"
      ..token2name = "USDT";
    await addPair(WBTC2USDT);
    */

    WBTC2ETH = Pair(
        5, client, "wbtc-eth", '0xbb2b8038a1640196fbe3e38816f3e67cba72d940');
    WBTC2ETH
      ..decimals1 = 8
      ..token1name = "WBTC"
      ..token2name = "ETH";
    await addPair(WBTC2ETH);
  }

  addPair(Pair p) async {
    await p.initialize();
    pairs[p.name] = p;
  }

  Pair? findPair(String name) {
    return pairs[name];
  }

  Pair? findPairById(int id) {
    for (var p in pairs.values) {
      if (p.id == id) return p;
    }
    return null;
  }

  Pair? findCOREPair(String name) {
    var p = findPair(name);
    if (p?.token1name == "CORE") {
      return p;
    }
    return null;
  }

  String pairNames() {
    return pairs.keys.join(", ");
  }

  String corePairNames() {
    return pairs.keys.where((k) => k.startsWith("core")).toList().join(", ");
  }

  /// Fetch pair stats if older than 1 minute
  fetchStats() async {
    if (statsTimestamp != null) {
      var limit = statsTimestamp?.add(Duration(minutes: 1)) as DateTime;
      if (DateTime.now().isAfter(limit)) {
        try {
          statsTimestamp = null; // Used as locking
          log.info("Fetching pair stats");
          var intervals = [0, 1, 6, 24, 48];
          await CORE2ETH.fetchDefaultStats(intervals);
          await CORE2CBTC.fetchDefaultStats(intervals);
          //await CORE2FANNY.fetchDefaultStats(intervals);
          //await CORE2CBTC.fetchDefaultStats(intervals);
          log.info("Fetching pair stats, done.");
        } finally {
          statsTimestamp = DateTime.now();
        }
      }
    }
  }
}
