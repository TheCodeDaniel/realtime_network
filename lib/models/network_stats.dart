class NetworkStats {
  final double downloadSpeed; // Mbps
  final double uploadSpeed; // Mbps
  final int ping; // ms
  final int jitter; // ms
  final String ip;
  final String isp;

  NetworkStats({
    required this.downloadSpeed,
    required this.uploadSpeed,
    required this.ping,
    required this.jitter,
    required this.ip,
    required this.isp,
  });

  factory NetworkStats.fromMap(Map<String, dynamic> map) {
    return NetworkStats(
      downloadSpeed: (map['downloadSpeed'] ?? 0).toDouble(),
      uploadSpeed: (map['uploadSpeed'] ?? 0).toDouble(),
      ping: map['ping'] ?? 0,
      jitter: map['jitter'] ?? 0,
      ip: map['ip'] ?? '',
      isp: map['isp'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'downloadSpeed': downloadSpeed, 'uploadSpeed': uploadSpeed, 'ping': ping, 'jitter': jitter, 'ip': ip, 'isp': isp};
  }

  @override
  String toString() {
    return 'NetworkStats(download: $downloadSpeed Mbps, upload: $uploadSpeed Mbps, ping: $ping ms, jitter: $jitter ms, ip: $ip, isp: $isp)';
  }
}
