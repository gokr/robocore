import 'package:robocore/contract.dart';

import 'package:robocore/ethclient.dart';

class Balancer extends Contract {
  Balancer(EthClient client)
      : super(client, 'Balancer.json',
            '0x30cb859317e171832b064c97cc03ccb081954d1b') {}

  Balancer.customAbi(EthClient client, String abi, String addressHex)
      : super(client, abi, addressHex) {}
}
