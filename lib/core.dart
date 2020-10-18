import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web_socket_channel/io.dart';

final pow18 = BigInt.from(pow(10, 18));
final pow8 = BigInt.from(pow(10, 8));
final pow6 = BigInt.from(pow(10, 6));

NumberFormat decimal6Formatter = NumberFormat("##0.00000#");
NumberFormat decimal4Formatter = NumberFormat("##0.000#");
NumberFormat decimal2Formatter = NumberFormat("##0.0#");
NumberFormat decimal0Formatter = NumberFormat("###");
NumberFormat dollar0Formatter =
    NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 0);
NumberFormat dollar2Formatter =
    NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 2);
String dec6(num x) => decimal6Formatter.format(x);
String dec4(num x) => decimal4Formatter.format(x);
String dec2(num x) => decimal2Formatter.format(x);
String dec0(num x) => decimal0Formatter.format(x);
String usd0(num x) => dollar0Formatter.format(x);
String usd2(num x) => dollar2Formatter.format(x);

/// From raw
num raw18(BigInt x) => (x / pow18).toDouble();
num raw8(BigInt x) => (x / pow8).toDouble();
num raw6(BigInt x) => (x / pow6).toDouble();

class Core {
  // Me
  late Credentials credentials;
  late EthereumAddress address;

  late Client httpClient;
  late Web3Client ethClient;

  // CORE contract address, CORE.json
  EthereumAddress coreAddr =
      EthereumAddress.fromHex('0x62359Ed7505Efc61FF1D56fEF82158CcaffA23D7');
  late DeployedContract core;

  // WBTC contract address
  EthereumAddress wbtcAddr =
      EthereumAddress.fromHex('0x2260fac5e5542a773aa44fbcfedf7c193bc2c599');
  late DeployedContract wbtc;

  // CoreVault contract address, CoreVault.json
  EthereumAddress coreVaultAddr =
      EthereumAddress.fromHex('0xc5cacb708425961594b63ec171f4df27a9c0d8c9');
  late DeployedContract coreVault;

  // UniswapPair CORE-ETH contract address, UniswapPair.json
  EthereumAddress CORE2ETHAddr =
      EthereumAddress.fromHex('0x32ce7e48debdccbfe0cd037cc89526e4382cb81b');
  late DeployedContract CORE2ETH;

  // LGE2 contract address, LGE2.json
  EthereumAddress LGE2Addr =
      EthereumAddress.fromHex('0xf7ca8f55c54cbb6d0965bc6d65c43adc500bc591');
  late DeployedContract LGE2;

  // IERC20 contract address, IERC20.json
  EthereumAddress IERC20Addr =
      EthereumAddress.fromHex('0xf7ca8f55c54cbb6d0965bc6d65c43adc500bc591');
  late DeployedContract IERC20;

  // UniswapPair ETH-USDT contract address, UniswapPair.json
  EthereumAddress ETH2USDTAddr =
      EthereumAddress.fromHex('0x0d4a11d5eeaac28ec3f61d100daf4d40471f1852');
  late DeployedContract ETH2USDT;

  // UniswapPair WBTC-USDT contract address, UniswapPair.json
  EthereumAddress WBTC2USDTAddr =
      EthereumAddress.fromHex('0x0de0fa91b6dbab8c8503aaa2d1dfa91a192cb149');
  late DeployedContract WBTC2USDT;

  Core(String apiUrl, String wsUrl) {
    httpClient = Client();
    ethClient = Web3Client(apiUrl, httpClient, socketConnector: () {
      return IOWebSocketChannel.connect(wsUrl).cast<String>();
    });
  }

  readContracts() async {
    await _extractAddress();
    await _readContracts();
  }

  factory Core.randomKey(String apiUrl, wsUrl) {
    return Core(apiUrl, wsUrl)
      ..credentials = EthPrivateKey.createRandom(Random.secure());
  }

  factory Core.privateKey(String privateKey, apiUrl, wsUrl) {
    return Core(apiUrl, wsUrl)..credentials = EthPrivateKey.fromHex(privateKey);
  }

  Future<EthereumAddress> _extractAddress() async {
    address = await credentials.extractAddress();
    return address;
  }

  _readContracts() async {
    core = await _readContract('CORE.json', coreAddr);
    wbtc = await _readContract('IERC20.json', wbtcAddr);
    coreVault = await _readContract('CoreVault.json', coreVaultAddr);
    CORE2ETH = await _readContract('UniswapPair.json', CORE2ETHAddr);
    ETH2USDT = await _readContract('UniswapPair.json', ETH2USDTAddr);
    WBTC2USDT = await _readContract('UniswapPair.json', WBTC2USDTAddr);
    LGE2 = await _readContract('cLGE.json', LGE2Addr);
  }

  Future<DeployedContract> _readContract(
      String filename, EthereumAddress address) async {
    var json = jsonDecode(await File(filename).readAsString());
    return DeployedContract(
        ContractAbi.fromJson(jsonEncode(json['abi']), json['contractName']),
        address);
  }

  /// Utility method to listen to a specific ContractEvent from a
  /// given DeployedContract.
  StreamSubscription<FilterEvent> listenToEvent(DeployedContract contract,
      String eventName, Function(ContractEvent, FilterEvent) handler) {
    final event = contract.event(eventName);
    return ethClient
        .events(FilterOptions.events(contract: contract, event: event))
        .listen((ev) {
      handler(event, ev);
    });
  }

  /// LGE
  Future<BigInt> totalLPTokensMinted() async {
    final minted = await ethClient.call(
        sender: address,
        contract: core,
        function: core.function('totalLPTokensMinted'),
        params: []);
    return minted.first;
  }

  /// LGE
  Future<BigInt> totalETHContributed() async {
    final eth = await ethClient.call(
        sender: address,
        contract: core,
        function: core.function('totalETHContributed'),
        params: []);
    return eth.first;
  }

  /// LGE2
  Future<BigInt> lge2TotalETHContributed() async {
    final eth = await ethClient.call(
        sender: address,
        contract: LGE2,
        function: LGE2.function('totalETHContributed'),
        params: []);
    return eth.first;
  }

  Future<BigInt> lge2TotalCOREContributed() async {
    final eth = await ethClient.call(
        sender: address,
        contract: LGE2,
        function: LGE2.function('totalCOREContributed'),
        params: []);
    return eth.first;
  }

  Future<BigInt> lge2TotalWrapTokenContributed() async {
    final eth = await ethClient.call(
        sender: address,
        contract: LGE2,
        function: LGE2.function('totalWrapTokenContributed'),
        params: []);
    return eth.first;
  }

  // LGE2 balanceOf
  // WBTC: 0x2260fac5e5542a773aa44fbcfedf7c193bc2c599
  // CORE: 0x62359Ed7505Efc61FF1D56fEF82158CcaffA23D7
  Future<BigInt> balanceOf(
      DeployedContract token, EthereumAddress ofToken) async {
    final core = await ethClient.call(
        sender: address,
        contract: token,
        function: token.function('balanceOf'),
        params: [ofToken]);
    return core.first;
  }

  Future<BigInt> cumulativeRewardsSinceStart() async {
    final core = await ethClient.call(
        sender: address,
        contract: coreVault,
        function: coreVault.function('cumulativeRewardsSinceStart'),
        params: []);
    return core.first;
  }

  Future<List<dynamic>> getReservesCORE2ETH() async {
    final result = await ethClient.call(
        sender: address,
        contract: CORE2ETH,
        function: CORE2ETH.function('getReserves'),
        params: []);
    return result;
  }

  Future<BigInt> totalSupplyCORE2ETH() async {
    final result = await ethClient.call(
        sender: address,
        contract: CORE2ETH,
        function: CORE2ETH.function('totalSupply'),
        params: []);
    return result.first;
  }

  Future<List<dynamic>> getReservesETH2USDT() async {
    final result = await ethClient.call(
        sender: address,
        contract: ETH2USDT,
        function: ETH2USDT.function('getReserves'),
        params: []);
    return result;
  }

  Future<List<dynamic>> getReservesWBTC2USDT() async {
    final result = await ethClient.call(
        sender: address,
        contract: WBTC2USDT,
        function: WBTC2USDT.function('getReserves'),
        params: []);
    return result;
  }

  Future<BigInt> price0CumulativeLast() async {
    final core = await ethClient.call(
        sender: address,
        contract: CORE2ETH,
        function: CORE2ETH.function('price0CumulativeLast'),
        params: []);
    return core.first;
  }

  Future<BigInt> price1CumulativeLast() async {
    final core = await ethClient.call(
        sender: address,
        contract: CORE2ETH,
        function: CORE2ETH.function('price1CumulativeLast'),
        params: []);
    return core.first;
  }

  Future<EtherAmount> getBalance() async {
    return ethClient.getBalance(address);
  }
}
