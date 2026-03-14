import AppKit

class SoundManager {
    static let shared = SoundManager()

    private var currentSound: NSSound?
    private var repeatTimer: Timer?
    private var repeatCount = 0
    private let maxRepeats = 5

    func playAlert() {
        stop()
        repeatCount = 0
        playOnce()
    }

    private func playOnce() {
        let soundName = UserDefaults.standard.string(forKey: "soundName") ?? "Basso"
        let isCustom = soundName == "custom"

        currentSound = makeSound()
        currentSound?.play()

        // Custom sounds play once; system sounds repeat up to maxRepeats times
        guard !isCustom, repeatCount < maxRepeats - 1 else { return }
        repeatCount += 1
        repeatTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            self?.playOnce()
        }
    }

    private func makeSound() -> NSSound? {
        let name = UserDefaults.standard.string(forKey: "soundName") ?? "Basso"
        let customPath = UserDefaults.standard.string(forKey: "customSoundPath") ?? ""

        if name == "custom" && !customPath.isEmpty {
            return NSSound(contentsOfFile: customPath, byReference: false)
        }
        return NSSound(named: name)
    }

    func stop() {
        repeatTimer?.invalidate()
        repeatTimer = nil
        currentSound?.stop()
        currentSound = nil
        repeatCount = 0
    }
}
