import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realtime_network/realtime_network.dart';
import 'package:realtime_network/models/network_stats.dart';
import 'package:realtime_network/realtime_network_method_channel.dart';
import 'package:realtime_network/realtime_network_platform_interface.dart';

/// A fake platform implementation for testing.
class FakeRealtimeNetworkPlatform extends RealtimeNetworkPlatform {
  bool listeningStarted = false;
  bool connectivityStarted = false;

  final _speedController = StreamController<NetworkStats>.broadcast();
  final _connectivityController = StreamController<bool>.broadcast();

  @override
  Stream<NetworkStats> startListening({int intervalSeconds = 10}) {
    listeningStarted = true;
    return _speedController.stream;
  }

  @override
  Future<void> stopListening() async {
    listeningStarted = false;
    await _speedController.close();
  }

  @override
  Future<NetworkStats> runTest() async {
    return NetworkStats(downloadSpeed: 42.5, uploadSpeed: 13.2, ping: 18, jitter: 4, ip: '192.168.0.0', isp: 'T-Mobile');
  }

  @override
  Stream<bool> listenConnectivity() {
    connectivityStarted = true;
    return _connectivityController.stream;
  }

  @override
  Future<void> stopConnectivityListening() async {
    connectivityStarted = false;
    await _connectivityController.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeRealtimeNetworkPlatform fakePlatform;

  setUp(() {
    fakePlatform = FakeRealtimeNetworkPlatform();
    RealtimeNetworkPlatform.instance = fakePlatform;
  });

  group('RealtimeNetwork', () {
    test('runTest() returns a valid NetworkStats object', () async {
      final result = await RealtimeNetwork.runTest();
      expect(result.downloadSpeed, 42.5);
      expect(result.uploadSpeed, 13.2);
      expect(result.ping, 18);
      expect(result.jitter, 4);
    });

    test('startListening() triggers listening state', () {
      final stream = RealtimeNetwork.startListening(intervalSeconds: 5);
      expect(fakePlatform.listeningStarted, true);
      expect(stream, isA<Stream<NetworkStats>>());
    });

    test('stopListening() stops listening', () async {
      await RealtimeNetwork.stopListening();
      expect(fakePlatform.listeningStarted, false);
    });

    test('listenConnectivity() triggers connectivity state', () {
      final stream = RealtimeNetwork.listenConnectivity();
      expect(fakePlatform.connectivityStarted, true);
      expect(stream, isA<Stream<bool>>());
    });

    test('stopConnectivityListening() stops connectivity listening', () async {
      await RealtimeNetwork.stopConnectivityListening();
      expect(fakePlatform.connectivityStarted, false);
    });
  });

  group('MethodChannelRealtimeNetwork', () {
    const MethodChannel channel = MethodChannel('realtime_network/methods');
    final log = <MethodCall>[];
    final methodChannel = MethodChannelRealtimeNetwork();

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
        log.add(call);
        if (call.method == 'runTest') {
          return {
            'downloadSpeed': 50.0,
            'uploadSpeed': 10.0,
            'ping': 20,
            'jitter': 5,
          };
        }
        return null;
      });
      log.clear();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    });

    test('runTest() invokes correct method and returns expected data', () async {
      final result = await methodChannel.runTest();
      expect(result.downloadSpeed, 50.0);
      expect(result.uploadSpeed, 10.0);
      expect(result.ping, 20);
      expect(result.jitter, 5);
      expect(log, [isA<MethodCall>().having((c) => c.method, 'method', 'runTest')]);
    });
  });
}
