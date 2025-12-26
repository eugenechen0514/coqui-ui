import SwiftUI
import AppKit

struct TTSInputView: View {
    @EnvironmentObject var viewModel: TTSViewModel
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Main content area
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Text input section
                    TextInputSection(text: $viewModel.inputText, isFocused: $isTextFieldFocused)

                    // Voice settings section
                    VoiceSettingsSection()

                    // Voice cloning section (if using XTTS)
                    if viewModel.selectedModel.contains("xtts") {
                        VoiceCloningSection()
                    }
                }
                .padding(20)
            }

            Divider()

            // Audio player and controls
            AudioControlBar()
        }
    }
}

// Native NSTextView wrapper for reliable text input
struct NativeTextView: NSViewRepresentable {
    @Binding var text: String

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView

        textView.isRichText = false
        textView.font = NSFont.systemFont(ofSize: 14)
        textView.textContainerInset = NSSize(width: 8, height: 8)
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.delegate = context.coordinator
        textView.string = text
        
        // Critical settings for editable text view
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        
        // Resizing behavior
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true

        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.borderType = .noBorder

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        let textView = nsView.documentView as! NSTextView
        if textView.string != text {
            textView.string = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: NativeTextView

        init(_ parent: NativeTextView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }
    }
}

struct TextInputSection: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Text to Synthesize", systemImage: "text.quote")
                .font(.headline)

            NativeTextView(text: $text)
                .frame(minHeight: 120, maxHeight: 200)
                .background(Color(nsColor: .textBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )

            HStack {
                Text("\(text.count) characters")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Button("Clear") {
                    text = ""
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                .disabled(text.isEmpty)
            }
        }
    }
}

struct VoiceSettingsSection: View {
    @EnvironmentObject var viewModel: TTSViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Voice Settings", systemImage: "slider.horizontal.3")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                // Model picker
                VStack(alignment: .leading, spacing: 4) {
                    Text("Model")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Picker("Model", selection: $viewModel.selectedModel) {
                        ForEach(viewModel.availableModels, id: \.self) { model in
                            Text(model.components(separatedBy: "/").last ?? model)
                                .tag(model)
                        }
                    }
                    .labelsHidden()
                }

                // Language picker
                VStack(alignment: .leading, spacing: 4) {
                    Text("Language")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Picker("Language", selection: $viewModel.selectedLanguage) {
                        ForEach(Language.allCases) { lang in
                            Text(lang.displayName).tag(lang.rawValue)
                        }
                    }
                    .labelsHidden()
                }

                // Speaker picker (if available)
                if !viewModel.availableSpeakers.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Speaker")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Picker("Speaker", selection: $viewModel.selectedSpeaker) {
                            Text("Default").tag(nil as String?)
                            ForEach(viewModel.availableSpeakers, id: \.self) { speaker in
                                Text(speaker).tag(speaker as String?)
                            }
                        }
                        .labelsHidden()
                    }
                }

                // Speed slider
                VStack(alignment: .leading, spacing: 4) {
                    Text("Speed: \(String(format: "%.1fx", viewModel.speed))")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Slider(value: $viewModel.speed, in: 0.5...2.0, step: 0.1)
                }
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct VoiceCloningSection: View {
    @EnvironmentObject var viewModel: TTSViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Voice Cloning", systemImage: "person.wave.2")
                    .font(.headline)

                Spacer()

                Toggle("Enable", isOn: $viewModel.useVoiceCloning)
                    .toggleStyle(.switch)
            }

            if viewModel.useVoiceCloning {
                HStack {
                    if let path = viewModel.referenceAudioPath {
                        Label(URL(fileURLWithPath: path).lastPathComponent, systemImage: "waveform")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)

                        Button {
                            viewModel.clearReferenceAudio()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                        }
                        .buttonStyle(.plain)
                    } else {
                        Text("No reference audio selected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button("Select Audio File") {
                        viewModel.selectReferenceAudio()
                    }
                }
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct AudioControlBar: View {
    @EnvironmentObject var viewModel: TTSViewModel

    var body: some View {
        VStack(spacing: 8) {
            // Progress bar
            if viewModel.audioPlayer.duration > 0 {
                HStack(spacing: 8) {
                    Text(viewModel.audioPlayer.formattedTime(viewModel.audioPlayer.currentTime))
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundColor(.secondary)

                    Slider(value: Binding(
                        get: { viewModel.audioPlayer.progress },
                        set: { viewModel.audioPlayer.seekToProgress($0) }
                    ))

                    Text(viewModel.audioPlayer.formattedTime(viewModel.audioPlayer.duration))
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            }

            // Control buttons
            HStack(spacing: 16) {
                // Play/Pause button
                Button {
                    if viewModel.audioPlayer.isPlaying {
                        viewModel.audioPlayer.pause()
                    } else if viewModel.synthesizedAudioData != nil {
                        viewModel.audioPlayer.resume()
                    }
                } label: {
                    Image(systemName: viewModel.audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title2)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.synthesizedAudioData == nil)

                // Stop button
                Button {
                    viewModel.audioPlayer.stop()
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.title2)
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.audioPlayer.isPlaying)

                Spacer()

                // Save button
                Button {
                    viewModel.saveCurrentAudio()
                } label: {
                    Label("Save", systemImage: "square.and.arrow.down")
                }
                .disabled(viewModel.synthesizedAudioData == nil)

                // Synthesize button
                Button {
                    Task {
                        await viewModel.synthesize()
                    }
                } label: {
                    HStack {
                        if viewModel.isSynthesizing {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "waveform")
                        }
                        Text("Synthesize")
                    }
                    .frame(minWidth: 120)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.inputText.isEmpty || viewModel.isSynthesizing || !viewModel.isServerRunning)
                .keyboardShortcut(.return, modifiers: .command)
            }
            .padding()
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

#Preview {
    TTSInputView()
        .environmentObject(TTSViewModel())
        .frame(width: 600, height: 500)
}
