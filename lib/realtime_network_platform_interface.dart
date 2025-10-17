import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:realtime_network/models/network_stats.dart';

import 'realtime_network_method_channel.dart';

/// Platform interface for RealtimeNetwork.
///
/// This defines the contract that all platform implementations (Android, iOS, Web, etc.)
/// must follow.

abstract class RealtimeNetworkPlatform extends PlatformInterface {
  RealtimeNetworkPlatform() : super(token: _token);

  static final Object _token = Object();

  static RealtimeNetworkPlatform _instance = MethodChannelRealtimeNetwork();

  /// The default instance of [RealtimeNetworkPlatform] to use.
  static RealtimeNetworkPlatform get instance => _instance;

  /// Allows platforms (iOS, macOS, etc.) to override the default implementation.
  static set instance(RealtimeNetworkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Listen for real-time network speed updates.
  Stream<NetworkStats> startListening({int intervalSeconds = 10}) {
    throw UnimplementedError('startListening() has not been implemented.');
  }

  /// Stop listening for updates.
  Future<void> stopListening() {
    throw UnimplementedError('stopListening() has not been implemented.');
  }

  /// Run a one-time speed test.
  Future<NetworkStats> runTest() {
    throw UnimplementedError('runTest() has not been implemented.');
  }

  /// Listen for real-time connectivity changes (online/offline).
  Stream<bool> listenConnectivity() {
    throw UnimplementedError('listenConnectivity() has not been implemented.');
  }

  /// Stop listening for connectivity changes.
  Future<void> stopConnectivityListening() {
    throw UnimplementedError('stopConnectivityListening() has not been implemented.');
  }
}
