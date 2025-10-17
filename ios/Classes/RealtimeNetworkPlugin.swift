import Flutter
import UIKit
import Network
import SystemConfiguration // For Reachability
import CoreTelephony     // For ISP/Carrier info

public class RealtimeNetworkPlugin: NSObject, FlutterPlugin {
    // MARK: - Flutter Setup
    
    // The channel name should match the Android implementation's MethodChannel name
    private static let channelName = "realtime_network/methods" 
    private var channel: FlutterMethodChannel!
    
    // MARK: - Concurrency and State
    
    // Use a Dispatch queue for background network operations
    private let backgroundQueue = DispatchQueue(label: "com.realnet.networktests", qos: .background)
    // A timer for the periodic network testing (startListening)
    private var networkTestTimer: Timer?
    
    // MARK: - Connectivity Monitoring
    
    // New API for iOS 12+ for monitoring connectivity
    private var connectivityMonitor: NWPathMonitor?
    // Old API for older iOS versions, but useful for basic network status
    private var reachability: SCNetworkReachability? 
    // State to track if the last reported connectivity was 'connected'
    private var lastConnectivityStatus: Bool? 
    
    // MARK: - Plugin Registration
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
        let instance = RealtimeNetworkPlugin()
        instance.channel = channel // Set the channel for instance methods
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    // MARK: - Handle Method Calls

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any]

        switch call.method {
        case "startListening":
            let interval = args?["interval"] as? Int ?? 10
            startListening(interval: interval)
            result(nil)
        
        case "stopListening":
            stopListening()
            result(nil)
            
        case "runTest":
            // Execute network test on a background thread
            backgroundQueue.async { [weak self] in
                guard let self = self else { return }
                let stats = self.getNetworkStats()
                
                // Return result to the main thread
                DispatchQueue.main.async {
                    result(stats)
                }
            }

        case "startConnectivityListening":
            startConnectivityListening()
            result(nil)

        case "stopConnectivityListening":
            stopConnectivityListening()
            result(nil)

        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - Periodic Network Testing (startListening/stopListening)

    private func startListening(interval: Int) {
        // Ensure only one timer is running
        stopListening() 
        
        // Start the first test immediately
        runPeriodicTest() 
        
        // Schedule the timer
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.networkTestTimer = Timer.scheduledTimer(
                timeInterval: TimeInterval(interval),
                target: self,
                selector: #selector(self.runPeriodicTest),
                userInfo: nil,
                repeats: true
            )
        }
    }

    @objc private func runPeriodicTest() {
        // Execute network test on a background thread
        backgroundQueue.async { [weak self] in
            guard let self = self else { return }
            let stats = self.getNetworkStats()
            
            // Invoke method on the main thread
            DispatchQueue.main.async {
                self.channel.invokeMethod("onNetworkStats", arguments: stats)
            }
        }
    }

    private func stopListening() {
        // Timers must be invalidated on the thread they were created on (Main thread)
        DispatchQueue.main.async { [weak self] in
            self?.networkTestTimer?.invalidate()
            self?.networkTestTimer = nil
        }
    }
    
    // MARK: - Network Stats Core Logic
    
    private func getNetworkStats() -> [String: Any] {
        // Use default values for all stats
        var pingAvg: Int = 0
        var jitter: Int = 0
        var downloadSpeed: Double = 0.0
        var uploadSpeed: Double = 0.0
        var ip: String = ""
        let isp = getNetworkProvider()
        
        // PING & JITTER
        (pingAvg, jitter) = runPingTest()
        
        // DOWNLOAD SPEED TEST
        downloadSpeed = runDownloadTest()
        
        // UPLOAD SPEED TEST
        uploadSpeed = runUploadTest()
        
        // PUBLIC IP
        ip = getPublicIP()

        return [
            "downloadSpeed": downloadSpeed,
            "uploadSpeed": uploadSpeed,
            "ping": pingAvg,
            "jitter": jitter,
            "ip": ip,
            "isp": isp
        ]
    }
    
    // MARK: - Implementation Helpers

    /** Runs a multi-ping test to 1.1.1.1 and calculates average ping and jitter. */
    private func runPingTest() -> (Int, Int) {
        // NOTE: iOS sandboxing makes direct ICMP ping tricky without elevated privileges 
        // or using third-party libraries. A simple HEAD request or socket connection 
        // to a reliable server is a pragmatic substitute for RTT (Round Trip Time) in Flutter plugins.
        // We'll use a HEAD request to a reliable server.
        
        let host = "1.1.1.1"
        let pingCount = 4
        var pingResults = [Double]()
        
        for _ in 1...pingCount {
            let startTime = CACurrentMediaTime()
            var duration: Double = 1.0 // Default 1000ms 
            
            let semaphore = DispatchSemaphore(value: 0)
            
            guard let url = URL(string: "https://\(host)") else { continue }
            var request = URLRequest(url: url)
            request.httpMethod = "HEAD"
            request.timeoutInterval = 2.0 // 2 second timeout
            
            let task = URLSession.shared.dataTask(with: request) { _, response, error in
                let endTime = CACurrentMediaTime()
                
                if let httpResponse = response as? HTTPURLResponse, 
                   (200...299).contains(httpResponse.statusCode) {
                    duration = endTime - startTime
                } 
                // else: Keep default duration (1.0s or 1000ms) for timeout/failure
                
                pingResults.append(duration * 1000.0) // Convert to milliseconds
                semaphore.signal()
            }
            task.resume()
            
            // Wait up to 2.5 seconds for the task to complete
            _ = semaphore.wait(timeout: .now() + 2.5) 
            
            // Introduce a short delay between pings, as in the Kotlin code
            Thread.sleep(forTimeInterval: 0.2) 
        }
        
        guard !pingResults.isEmpty else { return (0, 0) }
        
        let avgPing = Int(pingResults.average.rounded())
        var jitter: Int = 0
        
        if pingResults.count > 1 {
            let differences = (1..<pingResults.count).map { i in
                abs(pingResults[i] - pingResults[i-1])
            }
            jitter = Int(differences.average.rounded())
        }
        
        return (avgPing, jitter)
    }

    /** Runs a download speed test using a 10MB test file. */
    private func runDownloadTest() -> Double {
        let urlString = "https://speed.cloudflare.com/__down?bytes=10000000"
        let fileSize: Double = 10_000_000.0 // 10 MB in Bytes
        
        guard let url = URL(string: urlString) else { return 0.0 }
        
        let startTime = CACurrentMediaTime()
        let semaphore = DispatchSemaphore(value: 0)
        var timeElapsed: Double = 0.0
        
        let task = URLSession.shared.dataTask(with: url) { _, _, error in
            timeElapsed = CACurrentMediaTime() - startTime
            semaphore.signal()
        }
        task.resume()
        
        // Wait up to 10 seconds for the download to complete
        _ = semaphore.wait(timeout: .now() + 10.0) 
        
        guard timeElapsed > 0.0 else { return 0.0 }
        
        // (fileSize * 8) = total bits
        // bitsPerSecond = (fileSize * 8) / timeElapsed
        let bitsPerSecond = (fileSize * 8) / timeElapsed
        let mbps = bitsPerSecond / 1_000_000.0 // Mbps
        
        return (mbps * 100.0).rounded() / 100.0 // Round to 2 decimal places
    }

    /** Runs an upload speed test using a 1MB payload. */
    private func runUploadTest() -> Double {
        let urlString = "https://nbg1-speed.hetzner.com/upload.php"
        let payloadSize: Int = 1_000_000 // 1 MB
        
        guard let url = URL(string: urlString) else { return 0.0 }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = Data(repeating: 1, count: payloadSize) // 1MB dummy data
        
        let startTime = CACurrentMediaTime()
        let semaphore = DispatchSemaphore(value: 0)
        var timeElapsed: Double = 0.0
        
        let task = URLSession.shared.uploadTask(with: request, from: request.httpBody!) { _, _, _ in
            timeElapsed = CACurrentMediaTime() - startTime
            semaphore.signal()
        }
        task.resume()
        
        // Wait up to 10 seconds for the upload to complete
        _ = semaphore.wait(timeout: .now() + 10.0) 
        
        guard timeElapsed > 0.0 else { return 0.0 }
        
        // (payloadSize * 8) = total bits
        // bitsPerSecond = (payloadSize * 8) / timeElapsed
        let bitsPerSecond = (Double(payloadSize) * 8.0) / timeElapsed
        let mbps = bitsPerSecond / 1_000_000.0 // Mbps
        
        return (mbps * 100.0).rounded() / 100.0 // Round to 2 decimal places
    }

    /** Gets the public IP address. */
    private func getPublicIP() -> String {
        let ipUrl = URL(string: "https://api.ipify.org")!
        
        // Use a synchronous call for simplicity in a background thread
        do {
            let ip = try String(contentsOf: ipUrl).trimmingCharacters(in: .whitespacesAndNewlines)
            return ip
        } catch {
            return ""
        }
    }
    
    /** Gets the mobile carrier name. */
    private func getNetworkProvider() -> String {
        let telephonyInfo = CTTelephonyNetworkInfo()
        
        // In modern iOS, the carrier info is a dictionary keyed by the data service subscriber ID
        if #available(iOS 12.0, *) {
            guard let providers = telephonyInfo.serviceSubscriberCellularProviders else { return "Unknown" }
            // Get the name from the first available provider
            return providers.first?.value.carrierName ?? "Unknown"
        } else {
            return telephonyInfo.subscriberCellularProvider?.carrierName ?? "Unknown"
        }
    }
    
    // MARK: - Connectivity Listening (startConnectivityListening/stopConnectivityListening)

    /** Starts monitoring for network path changes. */
    private func startConnectivityListening() {
        // Use NWPathMonitor for modern, robust connectivity checks (iOS 12+)
        if #available(iOS 12.0, *) {
            connectivityMonitor = NWPathMonitor()
            // Set the monitor on the background queue for processing updates
            connectivityMonitor?.start(queue: backgroundQueue) 
            
            connectivityMonitor?.pathUpdateHandler = { [weak self] path in
                let isConnected = path.status == .satisfied
                
                // Only invoke the channel method if the status has actually changed
                if isConnected != self?.lastConnectivityStatus {
                    self?.lastConnectivityStatus = isConnected
                    // Send update to Flutter on the main thread
                    DispatchQueue.main.async {
                        self?.channel.invokeMethod("onConnectivityChanged", arguments: isConnected)
                    }
                }
            }
        } else {
            // Fallback for older iOS versions using Reachability (less reliable)
            // Note: Implementing SCNetworkReachability is more complex than simple NWPathMonitor. 
            // For a minimal working example, we'll rely on the newer API. 
            // In a production plugin, you'd add the SCNetworkReachability boilerplate here.
        }
    }

    /** Stops monitoring for network path changes. */
    private func stopConnectivityListening() {
        if #available(iOS 12.0, *) {
            connectivityMonitor?.cancel()
            connectivityMonitor = nil
            lastConnectivityStatus = nil
        }
    }
    
    // Deinitialization for cleanup
    deinit {
        stopListening()
        stopConnectivityListening()
    }
}

// MARK: - Extension for Average Calculation

// Helper extension to calculate the average of a Double array
private extension Array where Element == Double {
    var average: Double {
        isEmpty ? 0 : reduce(0, +) / Double(count)
    }
}