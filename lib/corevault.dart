import 'package:robocore/contract.dart';

import 'package:robocore/ethclient.dart';

class CoreVault extends Contract {
  CoreVault(EthClient client)
      : super(client, 'CoreVault.json',
            '0xc5cacb708425961594b63ec171f4df27a9c0d8c9') {}

  CoreVault.customAbi(EthClient client, String abi, String addressHex)
      : super(client, abi, addressHex) {}
}
