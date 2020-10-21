import 'dart:convert';

import 'package:http/http.dart';

class Etherscan {
  late Client httpClient;

  static const String host = "api.etherscan.io";
  String apiKey;

  Etherscan(this.apiKey) {
    httpClient = Client();
  }

  Future<Map> _transaction(String txn, String action, String module) async {
    var params = {
      "module": module,
      "action": action,
      "txhash": txn,
      "apikey": apiKey
    };
    var uri = Uri.https(host, '/api', params);
    var response = await httpClient.get(uri);
    return jsonDecode(response.body);
  }

  Future<Map> getstatus(String txn) async {
    return _transaction(txn, "getstatus", "transaction");
  }

  Future<Map> txlistinternal(String txn) async {
    return _transaction(txn, "txlistinternal", "account");
  }

  Future<Map> ethGetTransactionByHash(String txn) async {
    return _transaction(txn, "eth_getTransactionByHash", "proxy");
  }

  Future<Map> ethGetTransactionReceipt(String txn) async {
    return _transaction(txn, "eth_getTransactionReceipt", "proxy");
  }
}
