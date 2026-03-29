import Foundation
import UserNotifications

class AlertMonitorService: ObservableObject {
    static let alertTitle = "בדקות הקרובות צפויות להתקבל התרעות באזורך"

    @Published var isAlerting = false
    @Published var isSilentAlert = false
    @Published var alertLocations: [String] = []
    @Published var animationFrame: Int = 0
    @Published var statusText = "Starting..."
    @Published var lastCheckDate: Date?
    @Published var pulseFrame: Int = -1  // -1 = idle, 0-5 = animating (3 on/off flashes)

    private let apiURL = URL(string: "https://www.oref.org.il/warningMessages/alert/History/AlertsHistory.json")!

    private var pollTimer: Timer?
    private var animationTimer: Timer?
    private var dismissTimer: Timer?

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return f
    }()

    // MARK: - UserDefaults helpers

    private var pollInterval: TimeInterval {
        let v = UserDefaults.standard.double(forKey: "pollInterval")
        return v > 0 ? v : 30.0
    }

    private var lastAlertTimestamp: Date? {
        get {
            let ts = UserDefaults.standard.double(forKey: "lastAlertTimestamp")
            return ts > 0 ? Date(timeIntervalSince1970: ts) : nil
        }
        set {
            UserDefaults.standard.set(newValue?.timeIntervalSince1970 ?? 0, forKey: "lastAlertTimestamp")
        }
    }

    // MARK: - Lifecycle

    init() {
        requestNotificationPermission()
        start()
    }

    func start() {
        statusText = "Monitoring..."
        schedulePoll()
        performCheck()
    }

    func restartWithNewInterval() {
        pollTimer?.invalidate()
        schedulePoll()
    }

    // MARK: - Polling

    private func schedulePoll() {
        pollTimer?.invalidate()
        let timer = Timer(timeInterval: pollInterval, repeats: true) { [weak self] _ in
            self?.performCheck()
        }
        RunLoop.main.add(timer, forMode: .common)
        pollTimer = timer
    }

    private func performCheck() {
        var request = URLRequest(url: apiURL)
        request.setValue(
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
            forHTTPHeaderField: "User-Agent"
        )
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            DispatchQueue.main.async {
                self?.lastCheckDate = Date()
                self?.pulse()
                print("[\(Date().formatted(date: .omitted, time: .standard))] poll fired")
                if let data = data {
                    self?.processAlertData(data)
                } else {
                    self?.statusText = "Check failed"
                    if let error = error { print("API error: \(error)") }
                }
            }
        }.resume()
    }

    // MARK: - Demo mode

    func enableDemoMode() {
        guard let url = findDemoFile() else {
            statusText = "demo_alert.json not found next to app"
            return
        }
        guard let data = try? Data(contentsOf: url),
              let items = try? JSONDecoder().decode([AlertItem].self, from: data) else {
            statusText = "Failed to parse demo_alert.json"
            return
        }
        // Bypass all timestamp/recency checks for demo — trigger directly
        let matching = items.filter { $0.title == Self.alertTitle }
        guard !matching.isEmpty else {
            statusText = "No matching alert items in demo file"
            return
        }
        let locations = Array(Set(matching.map { $0.data })).sorted()
        triggerAlert(locations: locations)
    }

    private func pulse() {
        guard !isAlerting else { return }
        pulseFrame = 0
        advancePulse()
    }

    private func advancePulse() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            guard let self else { return }
            self.pulseFrame += 1
            if self.pulseFrame < 6 {
                self.advancePulse()
            } else {
                self.pulseFrame = -1
            }
        }
    }

    private func findDemoFile() -> URL? {
        let execPath = ProcessInfo.processInfo.arguments[0]
        let execDir = URL(fileURLWithPath: execPath).deletingLastPathComponent()

        // Search relative to executable (inside .app bundle and next to it)
        let candidates: [URL] = [
            // Next to the .app bundle
            execDir
                .deletingLastPathComponent() // MacOS
                .deletingLastPathComponent() // Contents
                .deletingLastPathComponent() // MyApp.app
                .appendingPathComponent("demo_alert.json"),
            // Inside bundle Resources
            execDir
                .deletingLastPathComponent()
                .appendingPathComponent("Resources/demo_alert.json"),
            // Current working directory
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent("demo_alert.json"),
        ]
        return candidates.first { FileManager.default.fileExists(atPath: $0.path) }
    }

    // MARK: - Detection

    private func processAlertData(_ data: Data) {
        // Empty or whitespace-only response means no active alerts
        let trimmed = data.filter { !($0 == 0x0D || $0 == 0x0A || $0 == 0x20 || $0 == 0x09) }
        if trimmed.isEmpty {
            if !isAlerting { statusText = "Monitoring... No active alerts" }
            return
        }
        guard let items = try? JSONDecoder().decode([AlertItem].self, from: data) else {
            statusText = "Response parse error"
            return
        }

        let matching = items.filter { $0.title == Self.alertTitle }
        guard !matching.isEmpty else {
            if !isAlerting { statusText = "Monitoring... No active alerts" }
            return
        }

        let timestamps = matching.compactMap { dateFormatter.date(from: $0.alertDate) }
        guard let mostRecent = timestamps.max() else { return }

        // Only fire if event is within the last 10 minutes
        // Only alert if event is within the last 5 minutes
        guard mostRecent > Date().addingTimeInterval(-300) else {
            if !isAlerting { statusText = "Monitoring... No recent alerts" }
            return
        }

        // Don't re-alert the exact same event cluster
        if let last = lastAlertTimestamp, mostRecent <= last { return }

        // Apply location filter (case-insensitive substring match)
        let filter = UserDefaults.standard.string(forKey: "locationFilter")?.trimmingCharacters(in: .whitespaces) ?? ""
        let allLocations = Array(Set(matching.map { $0.data })).sorted()
        let locations = filter.isEmpty
            ? allLocations
            : allLocations.filter { $0.localizedCaseInsensitiveContains(filter) }

        if locations.isEmpty {
            // Hardcoded text matched but location filter excluded it — silent alert (animation only)
            if !isAlerting && !isSilentAlert {
                lastAlertTimestamp = mostRecent
                triggerSilentAlert(locations: allLocations)
            }
            return
        }

        lastAlertTimestamp = mostRecent
        triggerAlert(locations: locations)
    }

    // MARK: - Alert

    private func triggerAlert(locations: [String]) {
        isSilentAlert = false
        isAlerting = true
        alertLocations = locations
        statusText = "⚠️ ALERT ACTIVE"

        startAnimation()
        SoundManager.shared.playAlert()
        sendNotification(locations: locations)

        // Auto-dismiss after 5 minutes
        dismissTimer?.invalidate()
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: false) { [weak self] _ in
            DispatchQueue.main.async { self?.dismissAlert() }
        }
    }

    private func triggerSilentAlert(locations: [String]) {
        isSilentAlert = true
        isAlerting = true
        alertLocations = locations
        statusText = "⚠️ Alert outside your area"

        startAnimation()
        // No sound — location filter didn't match

        // Auto-dismiss after 5 minutes
        dismissTimer?.invalidate()
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: false) { [weak self] _ in
            DispatchQueue.main.async { self?.dismissAlert() }
        }
    }

    func dismissAlert() {
        isAlerting = false
        isSilentAlert = false
        alertLocations = []
        stopAnimation()
        SoundManager.shared.stop()
        statusText = "Monitoring..."
    }

    // MARK: - Animation

    private func startAnimation() {
        animationTimer?.invalidate()
        animationFrame = 0
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { [weak self] _ in
            self?.animationFrame = ((self?.animationFrame ?? 0) + 1) % 4
        }
    }

    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
        animationFrame = 0
    }

    // MARK: - Notifications

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func sendNotification(locations: [String]) {
        let content = UNMutableNotificationContent()
        content.title = "⚠️ Missile Alert"
        content.body = locations.prefix(5).joined(separator: ", ")
        content.sound = .defaultCritical

        let req = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(req)
    }
}
