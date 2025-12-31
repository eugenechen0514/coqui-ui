import Foundation
import SwiftUI

class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @AppStorage("serverPort") var serverPort: Int = 5002
    @AppStorage("pythonPath") var pythonPath: String = "/opt/homebrew/bin/python3.11"
    @AppStorage("defaultModel") var defaultModel: String = "tts_models/en/ljspeech/tacotron2-DDC"
    @AppStorage("autoStartServer") var autoStartServer: Bool = false
    @AppStorage("outputDirectory") var outputDirectory: String = ""
    @AppStorage("defaultSpeed") var defaultSpeed: Double = 1.0
    @AppStorage("keepAudioHistory") var keepAudioHistory: Bool = true
    @AppStorage("maxHistoryItems") var maxHistoryItems: Int = 50

    private init() {
        if outputDirectory.isEmpty {
            outputDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.path ?? ""
        }
    }

    var serverURL: URL {
        URL(string: "http://localhost:\(serverPort)")!
    }
}

enum Language: String, CaseIterable, Identifiable {
    case english = "en"
    case chinese = "zh"
    case japanese = "ja"
    case korean = "ko"
    case german = "de"
    case french = "fr"
    case spanish = "es"
    case italian = "it"
    case portuguese = "pt"
    case russian = "ru"
    case arabic = "ar"
    case hindi = "hi"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english: return "English"
        case .chinese: return "中文"
        case .japanese: return "日本語"
        case .korean: return "한국어"
        case .german: return "Deutsch"
        case .french: return "Français"
        case .spanish: return "Español"
        case .italian: return "Italiano"
        case .portuguese: return "Português"
        case .russian: return "Русский"
        case .arabic: return "العربية"
        case .hindi: return "हिन्दी"
        }
    }
}
