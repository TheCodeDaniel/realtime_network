
import 'realtime_network_platform_interface.dart';

class RealtimeNetwork {
  Future<String?> getPlatformVersion() {
    return RealtimeNetworkPlatform.instance.getPlatformVersion();
  }
}
