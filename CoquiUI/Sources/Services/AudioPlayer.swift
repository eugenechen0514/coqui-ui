import Foundation
import AVFoundation

@MainActor
class AudioPlayer: ObservableObject {
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var progress: Double = 0

    private var player: AVAudioPlayer?
    private var timer: Timer?

    func play(data: Data) throws {
        stop()

        player = try AVAudioPlayer(data: data)
        player?.prepareToPlay()
        duration = player?.duration ?? 0

        player?.play()
        isPlaying = true

        startTimer()
    }

    func play(url: URL) throws {
        stop()

        player = try AVAudioPlayer(contentsOf: url)
        player?.prepareToPlay()
        duration = player?.duration ?? 0

        player?.play()
        isPlaying = true

        startTimer()
    }

    func pause() {
        player?.pause()
        isPlaying = false
        stopTimer()
    }

    func resume() {
        player?.play()
        isPlaying = true
        startTimer()
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
        currentTime = 0
        progress = 0
        stopTimer()
    }

    func seek(to time: TimeInterval) {
        player?.currentTime = time
        currentTime = time
        updateProgress()
    }

    func seekToProgress(_ value: Double) {
        let time = duration * value
        seek(to: time)
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updatePlaybackState()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func updatePlaybackState() {
        guard let player = player else { return }

        currentTime = player.currentTime
        updateProgress()

        if !player.isPlaying && currentTime >= duration - 0.1 {
            isPlaying = false
            currentTime = 0
            progress = 0
            stopTimer()
        }
    }

    private func updateProgress() {
        if duration > 0 {
            progress = currentTime / duration
        }
    }

    func formattedTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// Audio file management
extension AudioPlayer {
    func saveAudio(data: Data, filename: String? = nil) throws -> URL {
        let settings = AppSettings.shared
        let directory = URL(fileURLWithPath: settings.outputDirectory)

        let name = filename ?? "tts_\(Date().timeIntervalSince1970).wav"
        let fileURL = directory.appendingPathComponent(name)

        try data.write(to: fileURL)
        return fileURL
    }

    func getAudioInfo(data: Data) -> (sampleRate: Double, channels: Int, duration: TimeInterval)? {
        guard let player = try? AVAudioPlayer(data: data) else { return nil }

        return (
            sampleRate: player.format.sampleRate,
            channels: Int(player.format.channelCount),
            duration: player.duration
        )
    }
}
