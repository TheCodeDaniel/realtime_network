import 'dart:async';
import 'package:flutter/services.dart';
import 'package:realtime_network/models/network_stats.dart';
import 'realtime_network_platform_interface.dart';

/// MethodChannel-based implementation of [RealtimeNetworkPlatform].

class MethodChannelRealtimeNetwork extends RealtimeNetworkPlatform {
  static const MethodChannel _channel = MethodChannel('realtime_network/methods');

  StreamController<NetworkStats>? _speedStreamController;
  StreamController<bool>? _connectivityStreamController;

  @override
  Stream<NetworkStats> startListening({int intervalSeconds = 10}) {
    _speedStreamController ??= StreamController<NetworkStats>.broadcast(
      onListen: () {
        _channel.invokeMethod('startListening', {'interval': intervalSeconds});
      },
      onCancel: () {
        _channel.invokeMethod('stopListening');
        _speedStreamController = null;
      },
    );

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onNetworkStats') {
        final data = Map<String, dynamic>.from(call.arguments);
        final stats = NetworkStats.fromMap(data);
        _speedStreamController?.add(stats);
      } else if (call.method == 'onConnectivityChanged') {
        final bool isConnected = call.arguments as bool;
        _connectivityStreamController?.add(isConnected);
      }
    });

    return _speedStreamController!.stream;
  }

  @override
  Future<void> stopListening() async {
    await _channel.invokeMethod('stopListening');
    _speedStreamController?.close();
    _speedStreamController = null;
  }

  @override
  Future<NetworkStats> runTest() async {
    final result = await _channel.invokeMethod('runTest');
    return NetworkStats.fromMap(Map<String, dynamic>.from(result));
  }

  @override
  Stream<bool> listenConnectivity() {
    _connectivityStreamController ??= StreamController<bool>.broadcast(
      onListen: () {
        _channel.invokeMethod('startConnectivityListening');
      },
      onCancel: () {
        _channel.invokeMethod('stopConnectivityListening');
        _connectivityStreamController = null;
      },
    );

    return _connectivityStreamController!.stream;
  }

  @override
  Future<void> stopConnectivityListening() async {
    await _channel.invokeMethod('stopConnectivityListening');
    _connectivityStreamController?.close();
    _connectivityStreamController = null;
  }
}
