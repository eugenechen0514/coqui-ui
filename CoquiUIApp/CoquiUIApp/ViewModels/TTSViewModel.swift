import Foundation
import SwiftUI

@MainActor
class TTSViewModel: ObservableObject {
    // Input state
    @Published var inputText: String = ""
    @Published var selectedModel: String = "" {
        didSet {
            if selectedModel.contains("xtts") {
                useVoiceCloning = true
            }
        }
    }
    @Published var selectedSpeaker: String?
    @Published var selectedLanguage: String = "en"
    @Published var speed: Float = 1.0

    // Voice cloning
    @Published var referenceAudioPath: String?
    @Published var useVoiceCloning: Bool = false

    // Server state
    @Published var isServerRunning: Bool = false
    @Published var isLoading: Bool = false
    @Published var isSynthesizing: Bool = false

    // Data
    @Published var availableModels: [String] = []
    @Published var availableSpeakers: [String] = []
    @Published var availableLanguages: [String] = []
    @Published var synthesizedAudioData: Data?
    @Published var audioHistory: [AudioHistoryItem] = []

    // Error handling
    @Published var errorMessage: String?
    @Published var showError: Bool = false

    // Services
    let serverManager = PythonServiceManager()
    let audioPlayer = AudioPlayer()
    private let ttsService = TTSService()
    private let settings = AppSettings.shared

    struct AudioHistoryItem: Identifiable {
        let id = UUID()
        let text: String
        let audioData: Data
        let timestamp: Date
        let model: String
        let duration: TimeInterval?
    }

    init() {
        selectedModel = settings.defaultModel

        // Auto-start server if enabled
        if settings.autoStartServer {
            Task {
                await startServer()
            }
        }
    }

    // MARK: - Server Management

    func startServer() async {
        isLoading = true
        errorMessage = nil

        do {
            try await serverManager.startServer(model: selectedModel)

            // Wait for server to be ready
            try await Task.sleep(nanoseconds: 3_000_000_000)

            // Check if server is actually running
            isServerRunning = await ttsService.checkServerStatus()

            if isServerRunning {
                await loadModels()
                await loadSpeakers()
                await loadLanguages()
            } else {
                errorMessage = "Server started but not responding. Check logs for details."
                showError = true
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isLoading = false
    }

    func stopServer() {
        serverManager.stopServer()
        isServerRunning = false
        availableModels = []
        availableSpeakers = []
    }

    func checkServerStatus() async {
        isServerRunning = await ttsService.checkServerStatus()
    }

    // MARK: - Data Loading

    func loadModels() async {
        do {
            availableModels = try await ttsService.getModels()
        } catch {
            // Use default models list if server doesn't provide one
            availableModels = [
                "tts_models/en/ljspeech/tacotron2-DDC",
                "tts_models/en/ljspeech/glow-tts",
                "tts_models/en/ljspeech/vits",
                "tts_models/en/vctk/vits",
                "tts_models/multilingual/multi-dataset/xtts_v2"
            ]
        }
    }

    func loadSpeakers() async {
        do {
            availableSpeakers = try await ttsService.getSpeakers()
        } catch {
            availableSpeakers = []
        }
    }

    func loadLanguages() async {
        do {
            availableLanguages = try await ttsService.getLanguages()
        } catch {
            availableLanguages = Language.allCases.map { $0.rawValue }
        }
    }

    // MARK: - TTS Synthesis

    func synthesize() async {
        guard !inputText.isEmpty else {
            errorMessage = "Please enter some text to synthesize"
            showError = true
            return
        }

        guard isServerRunning else {
            errorMessage = "Server is not running. Please start the server first."
            showError = true
            return
        }

        // XTTS Validation
        if selectedModel.contains("xtts") {
            if !useVoiceCloning {
                useVoiceCloning = true
            }
            if referenceAudioPath == nil {
                errorMessage = "XTTS model requires a reference audio file. Please select one in the Voice Cloning section."
                showError = true
                return
            }
        }

        isSynthesizing = true
        errorMessage = nil

        do {
            let audioData: Data

            if useVoiceCloning, let refPath = referenceAudioPath {
                audioData = try await ttsService.synthesizeWithVoiceClone(
                    text: inputText,
                    referenceAudioPath: refPath,
                    language: selectedLanguage
                )
            } else {
                audioData = try await ttsService.synthesize(
                    text: inputText,
                    model: selectedModel,
                    speaker: selectedSpeaker,
                    language: selectedLanguage,
                    speed: speed
                )
            }

            synthesizedAudioData = audioData

            // Play the audio
            try audioPlayer.play(data: audioData)

            // Add to history
            if settings.keepAudioHistory {
                let historyItem = AudioHistoryItem(
                    text: inputText,
                    audioData: audioData,
                    timestamp: Date(),
                    model: selectedModel,
                    duration: audioPlayer.duration
                )
                audioHistory.insert(historyItem, at: 0)

                // Limit history size
                if audioHistory.count > settings.maxHistoryItems {
                    audioHistory.removeLast()
                }
            }

        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isSynthesizing = false
    }

    func playHistoryItem(_ item: AudioHistoryItem) {
        do {
            try audioPlayer.play(data: item.audioData)
        } catch {
            errorMessage = "Failed to play audio: \(error.localizedDescription)"
            showError = true
        }
    }

    func saveCurrentAudio() {
        guard let audioData = synthesizedAudioData else { return }

        do {
            let url = try audioPlayer.saveAudio(data: audioData)
            // Could show a success message or open the file in Finder
            NSWorkspace.shared.activateFileViewerSelecting([url])
        } catch {
            errorMessage = "Failed to save audio: \(error.localizedDescription)"
            showError = true
        }
    }

    func clearHistory() {
        audioHistory.removeAll()
    }

    // MARK: - Voice Cloning

    func selectReferenceAudio() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.wav, .mp3, .audio]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        if panel.runModal() == .OK {
            referenceAudioPath = panel.url?.path
        }
    }

    func clearReferenceAudio() {
        referenceAudioPath = nil
        useVoiceCloning = false
    }
}
