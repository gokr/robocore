import 'package:graphql/client.dart';
import 'package:robocore/graphqlwrapper.dart';
import 'package:web3dart/credentials.dart';
import 'package:web3dart/web3dart.dart';

late Uniswap uniswap;

class Uniswap extends GraphQLWrapper {
  late GraphQLClient client;

  final String uri =
      "https://api.thegraph.com/subgraphs/name/uniswap/uniswap-v2";

  Uniswap() {
    uniswap = this;
  }

  /// See https://uniswap.org/docs/v2/API/entities/
  Future<QueryResult?> pairStats(EthereumAddress pair) async {
    try {
      var options = QueryOptions(documentNode: gql(r'''
  query volumeStats($adr: String!) {
    pair(id: $adr){
      reserve0
      reserve1
      totalSupply
      reserveETH
      reserveUSD
      trackedReserveETH
      token0Price
      token1Price
      volumeToken0
      volumeToken1
      volumeUSD
      txCount
    }
  }
'''), variables: <String, dynamic>{'adr': pair.hex});
      var result = await client.query(options);
      return result;
    } catch (e) {
      return null;
    }
  }

  /// See https://uniswap.org/docs/v2/API/entities/
  Future<QueryResult?> pairStatsAtBlock(
      BlockNum block, EthereumAddress pair) async {
    try {
      var options = QueryOptions(documentNode: gql(r'''
  query volumeStats($adr: String!, $block: Int!) {
    pair(id: $adr, block: {number: $block}){
      reserve0
      reserve1
      totalSupply
      reserveETH
      reserveUSD
      trackedReserveETH
      token0Price
      token1Price
      volumeToken0
      volumeToken1
      volumeUSD
      txCount
    }
  }
'''), variables: <String, dynamic>{'adr': pair.hex, 'block': block.blockNum});
      var result = await client.query(options);
      return result;
    } catch (e) {
      return null;
    }
  }
}
