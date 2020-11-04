import 'dart:async';
import 'dart:math';

import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web_socket_channel/io.dart';

class EthClient {
  // Me
  late Credentials credentials;
  late EthereumAddress address;

  late Client httpClient;
  late Web3Client web3Client;

  EthClient(String apiUrl, String wsUrl) {
    httpClient = Client();
    web3Client = Web3Client(apiUrl, httpClient, socketConnector: () {
      return IOWebSocketChannel.connect(wsUrl).cast<String>();
    });
  }

  initialize() async {
    await _extractAddress();
  }

  factory EthClient.randomKey(String apiUrl, wsUrl) {
    return EthClient(apiUrl, wsUrl)
      ..credentials = EthPrivateKey.createRandom(Random.secure());
  }

  factory EthClient.privateKey(String privateKey, apiUrl, wsUrl) {
    return EthClient(apiUrl, wsUrl)
      ..credentials = EthPrivateKey.fromHex(privateKey);
  }

  Future<EthereumAddress> _extractAddress() async {
    address = await credentials.extractAddress();
    return address;
  }
}
