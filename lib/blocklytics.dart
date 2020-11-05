import 'package:graphql/client.dart';
import 'package:robocore/graphqlwrapper.dart';
import 'package:web3dart/web3dart.dart';

late Blocklytics blocklytics;

class Blocklytics extends GraphQLWrapper {
  late GraphQLClient client;

  final String uri =
      "https://api.thegraph.com/subgraphs/name/blocklytics/ethereum-blocks";

  Blocklytics() {
    blocklytics = this;
  }

  /// Return the exact BlockNum duration ago.
  Future<BlockNum?> blockAgo(Duration duration) async {
    return await blockNumAt(DateTime.now().subtract(duration));
  }

  /// Return the exact BlockNum at a given timestamp using a historical
  /// GraphQL query.
  Future<BlockNum?> blockNumAt(DateTime timestamp) async {
    var epoch = (timestamp.millisecondsSinceEpoch / 1000).round();
    var num = await blocklytics.blockNumberAt(epoch);
    return (num == 0) ? null : BlockNum.exact(num);
  }

  Future<int?> latestBlockNumber() async {
    try {
      var options = QueryOptions(documentNode: gql(r'''
  query LatestBlockNumber() {
    blocks(first: 1, skip: 0, orderBy: number, orderDirection: desc, where: {number_gt: 9300000}) {
      id
      number
      timestamp
    }
  }
'''));
      var result = await client.query(options);
      return int.parse(result.data['blocks'].first['number']);
    } catch (e) {
      return null;
    }
  }

  Future<int?> blockNumberAt(int epoch) async {
    try {
      var epoch2 = epoch + 20; // add 20 seconds
      var options = QueryOptions(documentNode: gql(r'''
  query BlockNumberAt($epoch: Int!, $epoch2: Int!) {
    blocks(first: 1, orderBy: timestamp, orderDirection: asc, where: {timestamp_gt: $epoch, timestamp_lt: $epoch2}) {
      id
      number
      timestamp
    }
  }
'''), variables: <String, dynamic>{'epoch': epoch, 'epoch2': epoch2});
      var result = await client.query(options);
      return int.parse(result.data['blocks'].first['number']);
    } catch (e) {
      return null;
    }
  }
}
