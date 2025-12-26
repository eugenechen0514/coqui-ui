import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            ServerSettingsView()
                .tabItem {
                    Label("Server", systemImage: "server.rack")
                }

            OutputSettingsView()
                .tabItem {
                    Label("Output", systemImage: "folder")
                }
        }
        .frame(width: 450, height: 300)
    }
}

struct GeneralSettingsView: View {
    @AppStorage("autoStartServer") private var autoStartServer = false
    @AppStorage("keepAudioHistory") private var keepAudioHistory = true
    @AppStorage("maxHistoryItems") private var maxHistoryItems = 50

    var body: some View {
        Form {
            Section {
                Toggle("Auto-start server on launch", isOn: $autoStartServer)

                Toggle("Keep audio history", isOn: $keepAudioHistory)

                if keepAudioHistory {
                    Stepper("Max history items: \(maxHistoryItems)", value: $maxHistoryItems, in: 10...200, step: 10)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct ServerSettingsView: View {
    @AppStorage("serverPort") private var serverPort = 5002
    @AppStorage("pythonPath") private var pythonPath = "/usr/local/bin/python3"
    @AppStorage("defaultModel") private var defaultModel = "tts_models/en/ljspeech/tacotron2-DDC"

    @State private var availablePythonPaths: [String] = []
    @State private var isTTSInstalled: Bool?

    var body: some View {
        Form {
            Section("Python Configuration") {
                Picker("Python Path", selection: $pythonPath) {
                    ForEach(availablePythonPaths, id: \.self) { path in
                        Text(path).tag(path)
                    }
                }

                HStack {
                    if let installed = isTTSInstalled {
                        Image(systemName: installed ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(installed ? .green : .red)
                        Text(installed ? "Coqui TTS installed" : "Coqui TTS not found")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button("Check") {
                        Task {
                            isTTSInstalled = await PythonServiceManager.checkTTSInstalled(pythonPath: pythonPath)
                        }
                    }
                }
            }

            Section("Server Configuration") {
                TextField("Port", value: $serverPort, format: .number)
                    .textFieldStyle(.roundedBorder)

                TextField("Default Model", text: $defaultModel)
                    .textFieldStyle(.roundedBorder)
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            availablePythonPaths = PythonServiceManager.findPythonInstallations()
            if availablePythonPaths.isEmpty {
                availablePythonPaths = [pythonPath]
            }
        }
    }
}

struct OutputSettingsView: View {
    @AppStorage("outputDirectory") private var outputDirectory = ""
    @AppStorage("defaultSpeed") private var defaultSpeed = 1.0

    var body: some View {
        Form {
            Section("Audio Output") {
                HStack {
                    TextField("Output Directory", text: $outputDirectory)
                        .textFieldStyle(.roundedBorder)

                    Button("Browse") {
                        let panel = NSOpenPanel()
                        panel.canChooseFiles = false
                        panel.canChooseDirectories = true
                        panel.allowsMultipleSelection = false

                        if panel.runModal() == .OK {
                            outputDirectory = panel.url?.path ?? ""
                        }
                    }
                }

                HStack {
                    Text("Default Speed")
                    Slider(value: $defaultSpeed, in: 0.5...2.0, step: 0.1)
                    Text(String(format: "%.1fx", defaultSpeed))
                        .monospacedDigit()
                        .frame(width: 40)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

#Preview {
    SettingsView()
}
