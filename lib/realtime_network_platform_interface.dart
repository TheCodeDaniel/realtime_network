import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'realtime_network_method_channel.dart';

abstract class RealtimeNetworkPlatform extends PlatformInterface {
  /// Constructs a RealtimeNetworkPlatform.
  RealtimeNetworkPlatform() : super(token: _token);

  static final Object _token = Object();

  static RealtimeNetworkPlatform _instance = MethodChannelRealtimeNetwork();

  /// The default instance of [RealtimeNetworkPlatform] to use.
  ///
  /// Defaults to [MethodChannelRealtimeNetwork].
  static RealtimeNetworkPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [RealtimeNetworkPlatform] when
  /// they register themselves.
  static set instance(RealtimeNetworkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
