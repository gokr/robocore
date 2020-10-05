import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:web3dart/web3dart.dart';

// Perhaps we should use something else?
const apiUrl = "https://mainnet.eth.aragon.network";

final pow18 = pow(10, 18);
final pow6 = pow(10, 6);

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
num raw18(BigInt x) => x.toDouble() / pow18;
num raw6(BigInt x) => x.toDouble() / pow6;

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

  // CoreVault contract address, CoreVault.json
  EthereumAddress coreVaultAddr =
      EthereumAddress.fromHex('0xc5cacb708425961594b63ec171f4df27a9c0d8c9');
  late DeployedContract coreVault;

  // UniswapPair CORE-ETH contract address, UniswapPair.json
  EthereumAddress CORE2ETHAddr =
      EthereumAddress.fromHex('0x32ce7e48debdccbfe0cd037cc89526e4382cb81b');
  late DeployedContract CORE2ETH;

  // UniswapPair ETH-USDT contract address, UniswapPair.json
  EthereumAddress ETH2USDTAddr =
      EthereumAddress.fromHex('0x0d4a11d5eeaac28ec3f61d100daf4d40471f1852');
  late DeployedContract ETH2USDT;

  Core() {
    httpClient = new Client();
    ethClient = new Web3Client(apiUrl, httpClient);
  }

  readContracts() async {
    await _extractAddress();
    await _readContracts();
  }

  factory Core.randomKey() {
    return Core()..credentials = EthPrivateKey.createRandom(Random.secure());
  }

  factory Core.privateKey(String privateKey) {
    return Core()..credentials = EthPrivateKey.fromHex(privateKey);
  }

  Future<EthereumAddress> _extractAddress() async {
    address = await credentials.extractAddress();
    return address;
  }

  _readContracts() async {
    core = await _readContract('CORE.json', coreAddr);
    coreVault = await _readContract('CoreVault.json', coreVaultAddr);
    CORE2ETH = await _readContract('UniswapPair.json', CORE2ETHAddr);
    ETH2USDT = await _readContract('UniswapPair.json', ETH2USDTAddr);
  }

  Future<DeployedContract> _readContract(
      String filename, EthereumAddress address) async {
    var json = jsonDecode(await File(filename).readAsString());
    return DeployedContract(
        ContractAbi.fromJson(jsonEncode(json['abi']), json['contractName']),
        address);
  }

  Future<BigInt> totalLPTokensMinted() async {
    final minted = await ethClient.call(
        sender: address,
        contract: core,
        function: core.function('totalLPTokensMinted'),
        params: []);
    return minted.first;
  }

  Future<BigInt> totalETHContributed() async {
    final eth = await ethClient.call(
        sender: address,
        contract: core,
        function: core.function('totalETHContributed'),
        params: []);
    return eth.first;
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

  Future<List<dynamic>> getReservesETH2USDT() async {
    final result = await ethClient.call(
        sender: address,
        contract: ETH2USDT,
        function: ETH2USDT.function('getReserves'),
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
