import 'package:graphql/client.dart';

abstract class GraphQLWrapper {
  late GraphQLClient client;

  static const String apiKey = "QmWTrJJ9W8h3JE19FhCzzPYsJ2tgXZCdUqnbyuo64ToTBN";

  // Implemented by subclasses
  String get uri;

  // Create a graphql client
  Future<GraphQLClient> connect(apiKey) async {
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
}
