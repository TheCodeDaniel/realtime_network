import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'realtime_network_platform_interface.dart';

/// An implementation of [RealtimeNetworkPlatform] that uses method channels.
class MethodChannelRealtimeNetwork extends RealtimeNetworkPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('realtime_network');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
