import Foundation

@MainActor
class PythonServiceManager: ObservableObject {
    @Published var isRunning = false
    @Published var logs: [String] = []
    @Published var currentModel: String?
    @Published var errorMessage: String?

    private var process: Process?
    private var outputPipe: Pipe?
    private var errorPipe: Pipe?
    private let settings = AppSettings.shared

    private var serverScriptPath: URL {
        // Look for the server script in the app bundle or in a known location
        if let bundlePath = Bundle.main.url(forResource: "tts_server", withExtension: "py") {
            return bundlePath
        }
        // Fallback to the CoquiTTSServer directory
        return URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("CoquiTTSServer")
            .appendingPathComponent("server.py")
    }

    func startServer(model: String? = nil) async throws {
        guard !isRunning else { return }

        let modelToUse = model ?? settings.defaultModel

        // First, try to use the TTS command-line server
        process = Process()
        outputPipe = Pipe()
        errorPipe = Pipe()

        process?.executableURL = URL(fileURLWithPath: settings.pythonPath)
        process?.arguments = [
            "-m", "TTS.server.server",
            "--port", String(settings.serverPort),
            "--model_name", modelToUse
        ]

        process?.standardOutput = outputPipe
        process?.standardError = errorPipe

        // Handle stdout
        outputPipe?.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if let output = String(data: data, encoding: .utf8), !output.isEmpty {
                Task { @MainActor in
                    self?.logs.append(output)
                    if self?.logs.count ?? 0 > 1000 {
                        self?.logs.removeFirst(100)
                    }
                }
            }
        }

        // Handle stderr
        errorPipe?.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if let output = String(data: data, encoding: .utf8), !output.isEmpty {
                Task { @MainActor in
                    self?.logs.append("[ERROR] \(output)")
                }
            }
        }

        process?.terminationHandler = { [weak self] _ in
            Task { @MainActor in
                self?.isRunning = false
                self?.currentModel = nil
            }
        }

        do {
            try process?.run()
            isRunning = true
            currentModel = modelToUse
            logs.append("Starting TTS server with model: \(modelToUse)")
            logs.append("Server running on port \(settings.serverPort)")

            // Wait a bit for the server to start
            try await Task.sleep(nanoseconds: 2_000_000_000)

        } catch {
            isRunning = false
            errorMessage = error.localizedDescription
            throw error
        }
    }

    func stopServer() {
        process?.terminate()
        process = nil
        outputPipe = nil
        errorPipe = nil
        isRunning = false
        currentModel = nil
        logs.append("Server stopped")
    }

    func restartServer(model: String? = nil) async throws {
        stopServer()
        try await Task.sleep(nanoseconds: 1_000_000_000)
        try await startServer(model: model)
    }

    func clearLogs() {
        logs.removeAll()
    }

    deinit {
        process?.terminate()
    }
}

// Extension to find Python installations
extension PythonServiceManager {
    static func findPythonInstallations() -> [String] {
        var paths: [String] = []

        let commonPaths = [
            "/usr/bin/python3",
            "/usr/local/bin/python3",
            "/opt/homebrew/bin/python3",
            "/opt/local/bin/python3"
        ]

        for path in commonPaths {
            if FileManager.default.fileExists(atPath: path) {
                paths.append(path)
            }
        }

        // Check for pyenv installations
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let pyenvPath = homeDir.appendingPathComponent(".pyenv/shims/python3").path
        if FileManager.default.fileExists(atPath: pyenvPath) {
            paths.append(pyenvPath)
        }

        // Check for conda installations
        let condaPath = homeDir.appendingPathComponent("miniconda3/bin/python3").path
        if FileManager.default.fileExists(atPath: condaPath) {
            paths.append(condaPath)
        }

        let anacondaPath = homeDir.appendingPathComponent("anaconda3/bin/python3").path
        if FileManager.default.fileExists(atPath: anacondaPath) {
            paths.append(anacondaPath)
        }

        return paths
    }

    static func checkTTSInstalled(pythonPath: String) async -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: pythonPath)
        process.arguments = ["-c", "import TTS; print(TTS.__version__)"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
}
