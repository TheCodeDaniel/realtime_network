import 'dart:async';
import 'package:realtime_network/models/network_stats.dart';
import 'realtime_network_platform_interface.dart';

class RealtimeNetwork {
  /// Run a one-time network speed test.
  static Future<NetworkStats> runTest() {
    return RealtimeNetworkPlatform.instance.runTest();
  }

  /// Start listening for network speed updates every [intervalSeconds].
  static Stream<NetworkStats> startListening({int intervalSeconds = 10}) {
    return RealtimeNetworkPlatform.instance.startListening(intervalSeconds: intervalSeconds);
  }

  /// Stop listening for network updates.
  static Future<void> stopListening() {
    return RealtimeNetworkPlatform.instance.stopListening();
  }

  /// Start listening for connectivity changes (true = online, false = offline).
  static Stream<bool> listenConnectivity() {
    return RealtimeNetworkPlatform.instance.listenConnectivity();
  }

  /// Stop connectivity monitoring.
  static Future<void> stopConnectivityListening() {
    return RealtimeNetworkPlatform.instance.stopConnectivityListening();
  }
}
