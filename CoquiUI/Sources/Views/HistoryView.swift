import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var viewModel: TTSViewModel
    @State private var searchText = ""

    var filteredHistory: [TTSViewModel.AudioHistoryItem] {
        if searchText.isEmpty {
            return viewModel.audioHistory
        }
        return viewModel.audioHistory.filter {
            $0.text.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Audio History")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                if !viewModel.audioHistory.isEmpty {
                    Button("Clear All") {
                        viewModel.clearHistory()
                    }
                    .foregroundColor(.red)
                }
            }
            .padding()

            Divider()

            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search history...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color(nsColor: .textBackgroundColor))
            .cornerRadius(8)
            .padding(.horizontal)
            .padding(.vertical, 8)

            // History list
            if filteredHistory.isEmpty {
                EmptyHistoryView(hasSearch: !searchText.isEmpty)
            } else {
                List {
                    ForEach(filteredHistory) { item in
                        HistoryItemRow(item: item)
                            .contextMenu {
                                Button("Play") {
                                    viewModel.playHistoryItem(item)
                                }
                                Button("Copy Text") {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(item.text, forType: .string)
                                }
                                Divider()
                                Button("Use as Input") {
                                    viewModel.inputText = item.text
                                }
                            }
                    }
                }
                .listStyle(.inset)
            }
        }
    }
}

struct HistoryItemRow: View {
    @EnvironmentObject var viewModel: TTSViewModel
    let item: TTSViewModel.AudioHistoryItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Play button
            Button {
                viewModel.playHistoryItem(item)
            } label: {
                Image(systemName: "play.circle.fill")
                    .font(.title)
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)

            // Text and metadata
            VStack(alignment: .leading, spacing: 4) {
                Text(item.text)
                    .lineLimit(2)
                    .font(.body)

                HStack(spacing: 8) {
                    Label(item.model.components(separatedBy: "/").last ?? item.model, systemImage: "cpu")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    if let duration = item.duration {
                        Label(formatDuration(duration), systemImage: "clock")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text(formatDate(item.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let seconds = Int(duration)
        if seconds < 60 {
            return "\(seconds)s"
        }
        return "\(seconds / 60)m \(seconds % 60)s"
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct EmptyHistoryView: View {
    let hasSearch: Bool

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: hasSearch ? "magnifyingglass" : "clock")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text(hasSearch ? "No matching items" : "No history yet")
                .font(.title3)
                .foregroundColor(.secondary)

            Text(hasSearch ? "Try a different search term" : "Synthesized audio will appear here")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    HistoryView()
        .environmentObject(TTSViewModel())
        .frame(width: 500, height: 400)
}
