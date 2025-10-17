# realtime_network

A comprehensive Flutter plugin for monitoring network statistics in real-time, including ping/latency, jitter, download/upload speed, and connectivity status.

This package is ideal for applications that require constant network performance diagnostics, such as real-time gaming, video conferencing, or health monitoring tools.

---

## ✨ Features

| Feature                   | Description                                                       |
| ------------------------- | ----------------------------------------------------------------- |
| **Real-time Monitoring**  | Get periodic network stats updates using `startListening()`.      |
| **Ping & Jitter**         | Calculates average Round Trip Time (RTT) and variance (Jitter).   |
| **Speed Tests**           | Executes dedicated Download and Upload speed tests (Mbps).        |
| **Connectivity Listener** | Reports instant changes in network availability (online/offline). |
| **IP & ISP Lookup**       | Retrieves the device's public IP address and ISP/Carrier name.    |

---

## 💻 Platforms Support

| Platform    | Status           | Note                              |
| ----------- | ---------------- | --------------------------------- |
| **Android** | ✅ Supported     | Requires permissions (see below). |
| **iOS**     | ✅ Supported     | Fully native implementation.      |
| **Windows** | ❌ Not Supported | Help wanted!                      |
| **Linux**   | ❌ Not Supported | Help wanted!                      |
| **Web**     | ❌ Not Supported | Help wanted!                      |
| **macOS**   | ⏳ Planned       |                                   |

---

## 🚀 Getting Started

### 1. Installation

Add `realtime_network` to your project's **pubspec.yaml** file:

```yaml
dependencies:
  realtime_network: ^latest # Use the latest version
```

Then run:

```bash
flutter pub get
```

### 2. Platform Setup

#### 📱 Android Setup

The plugin requires permissions for network testing and retrieving carrier information.  
Add these to your `android/app/src/main/AndroidManifest.xml` file, right before the `<application>` tag:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
<uses-permission android:name="android.permission.READ_PHONE_STATE"/>
```

#### 🍏 iOS Setup

No additional setup is required. The necessary native frameworks are automatically linked.

---

### 3. Usage

Import the package and get an instance of the class:

```dart
import 'package:realtime_network/realtime_network.dart';

final _networkPlugin = RealtimeNetwork();
```

#### A. Real-time Monitoring

Use streams to get continuous updates of network performance statistics (ping, jitter, speed):

```dart

// Subscribe to the stream to receive the results
_networkPlugin.startListening().listen((stats) {
      log('Download: ${stats.downloadSpeed} Mbps');
      log('Upload: ${stats.uploadSpeed} Mbps');
      log('Ping: ${stats.ping} ms');
      log('IP: ${stats.ip}');
      log('Jitter: ${stats.jitter}');
      log('Provider: ${stats.isp}');
});

 // You can customize the intervals to get realtime updates
.startListening(intervalSeconds: 5)

// ⚠️ IMPORTANT: Always stop the listener when your widget is disposed
@override
void dispose() {
  _networkPlugin.stopListening();
  super.dispose();
}
```

#### B. One-time Network Test

Run a full network performance test on demand:

```dart
try {
  final stats = await _networkPlugin.runTest();
  print('Test Complete: Ping=${stats.ping}ms, IP=${stats.ip}');
} catch (e) {
  print('Network test failed: $e');
}
```

#### C. Connectivity Status

Monitor when the device goes offline or comes back online:

```dart
// Start monitoring the connectivity state
_networkPlugin.startConnectivityListening();

// Subscribe to the stream to receive connectivity changes
_networkPlugin.startConnectivityListening().listen((bool isConnected) {
  if (isConnected) {
    print('Device is now ONLINE! 🟢');
  } else {
    print('Device is OFFLINE! 🔴');
  }
});

// ⚠️ IMPORTANT: Always stop the connectivity listener
@override
void dispose() {
  _networkPlugin.stopConnectivityListening();
  super.dispose();
}
```

---

## 📊 Data Structure

The `NetworkStats` object received by the streams and `runTest()` method contains the following fields:

| Field             | Type     | Description                                                  |
| ----------------- | -------- | ------------------------------------------------------------ |
| **downloadSpeed** | `double` | Measured download speed in Mbps (Megabits per second).       |
| **uploadSpeed**   | `double` | Measured upload speed in Mbps (Megabits per second).         |
| **ping**          | `int`    | Average Round Trip Time (RTT) in milliseconds (ms).          |
| **jitter**        | `int`    | Average variation between successive ping times in ms.       |
| **ip**            | `String` | The device's public IP address.                              |
| **isp**           | `String` | The name of the Internet Service Provider or mobile carrier. |

---

## 🤝 Contributing

We welcome contributions!  
If you have a fix or want to add support for a new platform, please submit a Pull Request.
to `https://github.com/TheCodeDaniel/realtime_network`

### TODO: Platform Integration

| Platform    | Status           | Priority |
| ----------- | ---------------- | -------- |
| **Windows** | ❌ Not Supported | High     |
| **Linux**   | ❌ Not Supported | Medium   |
| **Web**     | ❌ Not Supported | Medium   |
| **macOS**   | ⏳ Planned       | Low      |
