import 'package:graphql/client.dart';
import 'package:web3dart/credentials.dart';
import 'package:web3dart/web3dart.dart';

class Uniswap {
  late GraphQLClient client;

  static const String apiKey = "QmWTrJJ9W8h3JE19FhCzzPYsJ2tgXZCdUqnbyuo64ToTBN";
  static const String uri =
      "https://api.thegraph.com/subgraphs/name/uniswap/uniswap-v2";

  Uniswap() {}

  // Create a graphql client
  Future<GraphQLClient> connect() async {
    final HttpLink _httpLink = HttpLink(uri: uri);

    final AuthLink _authLink = AuthLink(
      getToken: () async => 'Bearer $apiKey',
    );

    final Link _link = _authLink.concat(_httpLink);

    client = GraphQLClient(
      cache: InMemoryCache(),
      link: _link,
    );
    return client;
  }

  static const String pairPrice = r'''
  query PairPriceAt($adr: String!, $block: Int!) {
    pair(id: $adr, block: {number: $block}) {
      id
      token1Price
    }
  }
''';

  Future<double> pairPriceAt(BlockNum block, EthereumAddress pair) async {
    try {
      var options = QueryOptions(
          documentNode: gql(pairPrice),
          variables: <String, dynamic>{
            'adr': pair.hex,
            'block': block.blockNum
          });
      var result = await client.query(options);
      return double.parse(result.data['pair']['token1Price']);
    } catch (e) {
      print("OUCH!");
      return 0;
    }
  }
}
