import 'package:robocore/contract.dart';
import 'package:robocore/ethclient.dart';
import 'package:robocore/pair.dart';
import 'package:robocore/token.dart';
import 'package:web3dart/web3dart.dart';

class Ethereum {
  EthClient client;

  late Token CORE, WBTC, WETH;

  Map<String, Pair> pairs = {};

  late Pair CORE2ETH;
  late Pair CORE2CBTC;
  late Pair ETH2USDT;
  late Pair WBTC2USDT;
  late Pair WBTC2ETH;

  late Contract LGE2, COREVAULT;

  Ethereum(this.client);

  initialize() async {
    // Tokens
    CORE = Token.customAbi(
        client, 'CORE.json', '0x62359Ed7505Efc61FF1D56fEF82158CcaffA23D7');
    await CORE.initialize();
    WBTC = Token(client, '0x2260fac5e5542a773aa44fbcfedf7c193bc2c599');
    await WBTC.initialize();
    WETH = Token(client, '0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2');
    await WETH.initialize();

    // Uniswap pairs
    CORE2ETH = Pair(
        1, client, "core-eth", '0x32ce7e48debdccbfe0cd037cc89526e4382cb81b');
    CORE2ETH
      ..token1name = "CORE"
      ..token2name = "ETH";
    await addPair(CORE2ETH);
    CORE2CBTC = Pair(
        2, client, "core-cbtc", '0x6fad7d44640c5cd0120deec0301e8cf850becb68');
    CORE2CBTC
      ..decimals2 = 8
      ..token1name = "CORE"
      ..token2name = "CBTC";
    await addPair(CORE2CBTC);
    ETH2USDT = Pair(
        3, client, "eth-usdt", '0x0d4a11d5eeaac28ec3f61d100daf4d40471f1852');
    ETH2USDT
      ..decimals2 = 6
      ..token1name = "ETH"
      ..token2name = "USDT";
    await addPair(ETH2USDT);
    WBTC2USDT = Pair(
        4, client, "wbtc-usdt", '0x0de0fa91b6dbab8c8503aaa2d1dfa91a192cb149');
    ETH2USDT
      ..decimals1 = 18
      ..decimals2 = 6
      ..token1name = "ETH"
      ..token2name = "USDT";
    await addPair(WBTC2USDT);
    WBTC2ETH = Pair(
        5, client, "wbtc-eth", '0xbb2b8038a1640196fbe3e38816f3e67cba72d940');
    WBTC2ETH
      ..decimals1 = 8
      ..token1name = "WBTC"
      ..token2name = "ETH";
    await addPair(WBTC2ETH);

    // Contracts
    LGE2 = Contract(
        client, 'cLGE.json', '0xf7ca8f55c54cbb6d0965bc6d65c43adc500bc591');
    await LGE2.initialize();
    COREVAULT = Contract(
        client, 'CoreVault.json', '0xc5cacb708425961594b63ec171f4df27a9c0d8c9');
    await COREVAULT.initialize();
  }

  addPair(Pair p) async {
    await p.initialize();
    pairs[p.name] = p;
  }

  Pair? findPair(String name) {
    return pairs[name];
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
}
