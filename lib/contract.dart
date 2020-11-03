import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:robocore/ethclient.dart';
import 'package:web3dart/web3dart.dart';

class Contract {
  String abi;
  EthClient client;
  late EthereumAddress address;
  late DeployedContract contract;

  Contract(this.client, this.abi, String addressHex) {
    address = EthereumAddress.fromHex(addressHex);
  }

  initialize() async {
    contract = await _readContract(abi, address);
  }

  Future<DeployedContract> _readContract(
      String filename, EthereumAddress address) async {
    var json = jsonDecode(await File(filename).readAsString());
    return DeployedContract(
        ContractAbi.fromJson(jsonEncode(json['abi']), json['contractName']),
        address);
  }

  /// Utility method to listen to a specific ContractEvent.
  StreamSubscription<FilterEvent> listenToEvent(
      String eventName, Function(ContractEvent, FilterEvent) handler) {
    final event = contract.event(eventName);
    return client.web3Client
        .events(FilterOptions.events(contract: contract, event: event))
        .listen((ev) {
      handler(event, ev);
    });
  }

  Future<EtherAmount> getBalance() async {
    return client.web3Client.getBalance(address);
  }

  Future<List> callFunction(String name, [List<dynamic>? params]) async {
    return await client.web3Client.call(
        sender: client.address,
        contract: contract,
        function: contract.function(name),
        params: params ?? []);
  }
}
