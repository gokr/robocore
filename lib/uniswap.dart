import 'package:graphql/client.dart';

class Uniswap {
  late GraphQLClient client;

  static const String url =
      "https://thegraph.com/explorer/subgraph/uniswap/uniswap-v2";
  String apiKey;

  Uniswap(this.apiKey) {}

  // Create a graphql client
  Future<GraphQLClient> connect() async {
    final HttpLink _httpLink = HttpLink(uri: 'https://api.github.com/graphql');

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
}
