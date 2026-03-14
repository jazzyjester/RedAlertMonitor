import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject var monitor: AlertMonitorService

    @AppStorage("pollInterval")    private var pollInterval: Double = 30
    @AppStorage("soundName")       private var soundName: String   = "Basso"
    @AppStorage("customSoundPath") private var customSoundPath: String = ""

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            Divider()
            settingsBody
            Divider()
            aboutSection
        }
        .frame(width: 440)
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Header

    private var headerSection: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hue: 0.02, saturation: 0.85, brightness: 0.22),
                    Color(hue: 0.00, saturation: 0.75, brightness: 0.14),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.25))
                        .frame(width: 56, height: 56)
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.orange)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Red Alert Monitor")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                    Text("Real-time missile alert monitoring for Israel")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.65))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Circle()
                        .fill(monitor.isAlerting ? Color.red : Color.green)
                        .frame(width: 8, height: 8)
                        .shadow(color: monitor.isAlerting ? .red : .green, radius: 4)
                    Text(monitor.isAlerting ? "ALERT" : "Active")
                        .font(.caption2.bold())
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
    }

    // MARK: - Settings body

    private var settingsBody: some View {
        VStack(spacing: 16) {
            settingsCard(
                icon: "clock.arrow.circlepath",
                iconColor: .blue,
                title: "Check Interval",
                subtitle: "How often to poll the alert API"
            ) {
                Picker("", selection: $pollInterval) {
                    Text("Every 30 seconds").tag(30.0)
                    Text("Every 60 seconds").tag(60.0)
                }
                .pickerStyle(.radioGroup)
                .labelsHidden()
                .onChange(of: pollInterval) { _ in
                    monitor.restartWithNewInterval()
                }
            }

            settingsCard(
                icon: "speaker.wave.3.fill",
                iconColor: .purple,
                title: "Alert Sound",
                subtitle: "Played when a missile alert is detected"
            ) {
                VStack(alignment: .leading, spacing: 10) {
                    Picker("", selection: $soundName) {
                        Text("Basso").tag("Basso")
                        Text("Funk").tag("Funk")
                        Text("Hero").tag("Hero")
                        Text("Sosumi").tag("Sosumi")
                        Divider()
                        Text("Custom file…").tag("custom")
                    }
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if soundName == "custom" {
                        HStack {
                            Image(systemName: "doc.badge.music")
                                .foregroundStyle(.secondary)
                            Text(customSoundPath.isEmpty
                                 ? "No file selected"
                                 : URL(fileURLWithPath: customSoundPath).lastPathComponent)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Spacer()
                            Button("Browse…") { selectCustomSound() }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                        }
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 6)
                            .fill(Color(NSColor.controlBackgroundColor)))
                    }

                    HStack(spacing: 8) {
                        Button {
                            SoundManager.shared.playAlert()
                        } label: {
                            Label("Test Sound", systemImage: "play.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        .controlSize(.small)

                        Button {
                            SoundManager.shared.stop()
                        } label: {
                            Label("Stop", systemImage: "stop.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .controlSize(.small)
                    }
                }
            }
        }
        .padding(20)
    }

    // MARK: - About footer

    private var aboutSection: some View {
        VStack(spacing: 10) {
            HStack(spacing: 24) {
                aboutStat(value: "< 30s", label: "Alert latency")
                Divider().frame(height: 28)
                aboutStat(value: "24/7", label: "Monitoring")
                Divider().frame(height: 28)
                aboutStat(value: "IDF", label: "Data source")
            }

            Text("Powered by the Israel Home Front Command (Pikud HaOref) official API. Monitors incoming missile threats and delivers instant alerts so you and your family can reach safety in time.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)

            Text("Version 1.0  •  Stay safe 🛡️")
                .font(.caption2)
                .foregroundStyle(Color.secondary.opacity(0.6))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
    }

    private func aboutStat(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.callout, design: .rounded).bold())
                .foregroundStyle(.primary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Card helper

    private func settingsCard<Content: View>(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 30, height: 30)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(iconColor)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            content()
                .padding(.leading, 4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
        )
    }

    // MARK: - File picker

    private func selectCustomSound() {
        let panel = NSOpenPanel()
        panel.title = "Select Sound File"
        panel.allowedContentTypes = [.audio]
        if panel.runModal() == .OK, let url = panel.url {
            customSoundPath = url.path
            soundName = "custom"
        }
    }
}
