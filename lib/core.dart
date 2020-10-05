import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:web3dart/web3dart.dart';

// Perhaps we should use something else?
const apiUrl = "https://mainnet.eth.aragon.network";

final raw = pow(10, 18);

NumberFormat decimal4Formatter = NumberFormat("###.000#");
NumberFormat decimal2Formatter = NumberFormat("###.0#");
NumberFormat decimal0Formatter = NumberFormat("###");
String dec4(num x) => decimal4Formatter.format(x);
String dec2(num x) => decimal2Formatter.format(x);
String dec0(num x) => decimal0Formatter.format(x);

/// Get 18 decimal point
num raw2real(BigInt x) => x.toDouble() / raw;

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

  // UniswapPair contract address, UniswapPair.json
  EthereumAddress uniswapPairAddr =
      EthereumAddress.fromHex('0x32ce7e48debdccbfe0cd037cc89526e4382cb81b');
  late DeployedContract uniswapPair;

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
    uniswapPair = await _readContract('UniswapPair.json', uniswapPairAddr);
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

  Future<List<dynamic>> getReserves() async {
    final result = await ethClient.call(
        sender: address,
        contract: uniswapPair,
        function: uniswapPair.function('getReserves'),
        params: []);
    return result;
  }

  Future<BigInt> price0CumulativeLast() async {
    final core = await ethClient.call(
        sender: address,
        contract: uniswapPair,
        function: uniswapPair.function('price0CumulativeLast'),
        params: []);
    return core.first;
  }

  Future<BigInt> price1CumulativeLast() async {
    final core = await ethClient.call(
        sender: address,
        contract: uniswapPair,
        function: uniswapPair.function('price1CumulativeLast'),
        params: []);
    return core.first;
  }

  Future<EtherAmount> getBalance() async {
    return ethClient.getBalance(address);
  }
}
