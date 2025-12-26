import Foundation

actor TTSService {
    private let settings = AppSettings.shared
    private var session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: config)
    }

    func synthesize(text: String, model: String? = nil, speaker: String? = nil, language: String? = nil, speed: Float = 1.0) async throws -> Data {
        var components = URLComponents(url: settings.serverURL.appendingPathComponent("api/tts"), resolvingAgainstBaseURL: false)!

        var queryItems = [URLQueryItem(name: "text", value: text)]

        if let speaker = speaker {
            queryItems.append(URLQueryItem(name: "speaker_id", value: speaker))
        }
        if let language = language {
            queryItems.append(URLQueryItem(name: "language_id", value: language))
        }
        if speed != 1.0 {
            queryItems.append(URLQueryItem(name: "speed", value: String(speed)))
        }

        components.queryItems = queryItems

        guard let url = components.url else {
            throw TTSError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TTSError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let errorMessage = String(data: data, encoding: .utf8) {
                throw TTSError.serverError(errorMessage)
            }
            throw TTSError.httpError(httpResponse.statusCode)
        }

        return data
    }

    func synthesizeWithVoiceClone(text: String, referenceAudioPath: String, language: String) async throws -> Data {
        let url = settings.serverURL.appendingPathComponent("api/tts")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // Add text field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"text\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(text)\r\n".data(using: .utf8)!)

        // Add language field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"language_id\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(language)\r\n".data(using: .utf8)!)

        // Add reference audio file
        if let audioData = FileManager.default.contents(atPath: referenceAudioPath) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"speaker_wav\"; filename=\"reference.wav\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
            body.append(audioData)
            body.append("\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw TTSError.serverError("Voice cloning failed")
        }

        return data
    }

    func getModels() async throws -> [String] {
        let url = settings.serverURL.appendingPathComponent("api/models")

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw TTSError.invalidResponse
        }

        let models = try JSONDecoder().decode([String].self, from: data)
        return models
    }

    func checkServerStatus() async -> Bool {
        do {
            let url = settings.serverURL
            let (_, response) = try await session.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse else {
                return false
            }
            return httpResponse.statusCode == 200
        } catch {
            return false
        }
    }

    func getSpeakers() async throws -> [String] {
        let url = settings.serverURL.appendingPathComponent("api/speakers")

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return []
        }

        let speakers = try JSONDecoder().decode([String].self, from: data)
        return speakers
    }

    func getLanguages() async throws -> [String] {
        let url = settings.serverURL.appendingPathComponent("api/languages")

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return []
        }

        let languages = try JSONDecoder().decode([String].self, from: data)
        return languages
    }
}

enum TTSError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case serverError(String)
    case audioPlaybackFailed
    case serverNotRunning

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL configuration"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP Error: \(code)"
        case .serverError(let message):
            return "Server Error: \(message)"
        case .audioPlaybackFailed:
            return "Failed to play audio"
        case .serverNotRunning:
            return "TTS server is not running. Please start the server first."
        }
    }
}
