import SwiftUI

struct LogsView: View {
    @EnvironmentObject var viewModel: TTSViewModel
    @State private var autoScroll = true
    @State private var searchText = ""

    var filteredLogs: [String] {
        if searchText.isEmpty {
            return viewModel.serverManager.logs
        }
        return viewModel.serverManager.logs.filter {
            $0.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Server Logs")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Toggle("Auto-scroll", isOn: $autoScroll)
                    .toggleStyle(.switch)
                    .controlSize(.small)

                Button {
                    viewModel.serverManager.clearLogs()
                } label: {
                    Label("Clear", systemImage: "trash")
                }
            }
            .padding()

            Divider()

            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Filter logs...", text: $searchText)
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

            // Logs content
            if filteredLogs.isEmpty {
                EmptyLogsView()
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 2) {
                            ForEach(Array(filteredLogs.enumerated()), id: \.offset) { index, log in
                                LogLine(text: log)
                                    .id(index)
                            }
                        }
                        .padding()
                    }
                    .background(Color(nsColor: .textBackgroundColor))
                    .onChange(of: viewModel.serverManager.logs.count) { _, _ in
                        if autoScroll {
                            withAnimation {
                                proxy.scrollTo(filteredLogs.count - 1, anchor: .bottom)
                            }
                        }
                    }
                }
            }

            Divider()

            // Status bar
            LogsStatusBar()
        }
    }
}

struct LogLine: View {
    let text: String

    var logLevel: LogLevel {
        if text.contains("[ERROR]") || text.lowercased().contains("error") {
            return .error
        } else if text.lowercased().contains("warning") || text.lowercased().contains("warn") {
            return .warning
        } else if text.lowercased().contains("info") {
            return .info
        }
        return .debug
    }

    enum LogLevel {
        case debug, info, warning, error

        var color: Color {
            switch self {
            case .debug: return .secondary
            case .info: return .primary
            case .warning: return .orange
            case .error: return .red
            }
        }
    }

    var body: some View {
        Text(text)
            .font(.system(.caption, design: .monospaced))
            .foregroundColor(logLevel.color)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct EmptyLogsView: View {
    @EnvironmentObject var viewModel: TTSViewModel

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "terminal")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No logs yet")
                .font(.title3)
                .foregroundColor(.secondary)

            if !viewModel.isServerRunning {
                Text("Start the server to see logs")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .textBackgroundColor))
    }
}

struct LogsStatusBar: View {
    @EnvironmentObject var viewModel: TTSViewModel

    var body: some View {
        HStack {
            Circle()
                .fill(viewModel.isServerRunning ? Color.green : Color.gray)
                .frame(width: 8, height: 8)

            Text(viewModel.isServerRunning ? "Server running" : "Server stopped")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            Text("\(viewModel.serverManager.logs.count) lines")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}

#Preview {
    LogsView()
        .environmentObject(TTSViewModel())
        .frame(width: 600, height: 400)
}
