import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:realtime_network/realtime_network.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _handleRealtime();
  }

  _handleRealtime() {
    RealtimeNetwork.startListening().listen((stats) {
      log('Download: ${stats.downloadSpeed} Mbps');
      log('Upload: ${stats.uploadSpeed} Mbps');
      log('Ping: ${stats.ping} ms');
      log('IP: ${stats.ip}');
      log('Jitter: ${stats.jitter}');
      log('Provider: ${stats.isp}');
    });
    // RealtimeNetwork.listenConnectivity().listen((isConnected) {
    //   log('Connectivity: $isConnected');
    // });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Plugin example app')),
        body: Center(child: Text('Values')),
      ),
    );
  }
}
