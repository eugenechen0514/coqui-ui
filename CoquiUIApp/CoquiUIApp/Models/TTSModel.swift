import Foundation

struct TTSModel: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let language: String
    let description: String
    let modelType: ModelType
    let isDownloaded: Bool

    enum ModelType: String, Codable, CaseIterable {
        case tacotron2 = "tacotron2"
        case vits = "vits"
        case xtts = "xtts"
        case glowtts = "glow-tts"
        case fastspeech = "fastspeech"
        case yourtts = "yourtts"

        var displayName: String {
            switch self {
            case .tacotron2: return "Tacotron 2"
            case .vits: return "VITS"
            case .xtts: return "XTTS v2"
            case .glowtts: return "Glow-TTS"
            case .fastspeech: return "FastSpeech"
            case .yourtts: return "YourTTS"
            }
        }
    }
}

struct Voice: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let language: String
    let gender: Gender?
    let sampleAudioURL: URL?

    enum Gender: String, Codable {
        case male = "male"
        case female = "female"
        case neutral = "neutral"
    }
}

struct TTSRequest: Codable {
    let text: String
    let modelName: String?
    let speakerIdx: String?
    let languageIdx: String?
    let speakerWav: String?
    let speed: Float?

    enum CodingKeys: String, CodingKey {
        case text
        case modelName = "model_name"
        case speakerIdx = "speaker_idx"
        case languageIdx = "language_idx"
        case speakerWav = "speaker_wav"
        case speed
    }
}

struct TTSResponse: Codable {
    let audioURL: URL?
    let audioData: Data?
    let duration: Double?
    let error: String?
}

struct ServerStatus: Codable {
    let isRunning: Bool
    let modelLoaded: String?
    let availableModels: [String]?
    let port: Int
}
