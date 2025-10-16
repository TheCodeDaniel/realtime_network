import 'package:flutter_test/flutter_test.dart';
import 'package:realtime_network/realtime_network.dart';
import 'package:realtime_network/realtime_network_platform_interface.dart';
import 'package:realtime_network/realtime_network_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockRealtimeNetworkPlatform
    with MockPlatformInterfaceMixin
    implements RealtimeNetworkPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final RealtimeNetworkPlatform initialPlatform = RealtimeNetworkPlatform.instance;

  test('$MethodChannelRealtimeNetwork is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelRealtimeNetwork>());
  });

  test('getPlatformVersion', () async {
    RealtimeNetwork realtimeNetworkPlugin = RealtimeNetwork();
    MockRealtimeNetworkPlatform fakePlatform = MockRealtimeNetworkPlatform();
    RealtimeNetworkPlatform.instance = fakePlatform;

    expect(await realtimeNetworkPlugin.getPlatformVersion(), '42');
  });
}
