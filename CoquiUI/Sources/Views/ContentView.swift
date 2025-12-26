import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: TTSViewModel
    @State private var selectedTab: Tab = .synthesize

    enum Tab: String, CaseIterable {
        case synthesize = "Synthesize"
        case history = "History"
        case models = "Models"
        case logs = "Logs"
    }

    var body: some View {
        HSplitView {
            // Sidebar
            VStack(spacing: 0) {
                List(Tab.allCases, id: \.self, selection: $selectedTab) { tab in
                    Label {
                        Text(tab.rawValue)
                    } icon: {
                        tabIcon(for: tab)
                    }
                    .tag(tab)
                }
                .listStyle(.sidebar)

                Divider()

                ServerControlView()
                    .padding()
            }
            .frame(minWidth: 180, maxWidth: 220)

            // Main content
            VStack {
                switch selectedTab {
                case .synthesize:
                    TTSInputView()
                case .history:
                    HistoryView()
                case .models:
                    ModelManagerView()
                case .logs:
                    LogsView()
                }
            }
            .frame(minWidth: 500)
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                ServerStatusView()
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {
                viewModel.showError = false
            }
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred")
        }
    }

    @ViewBuilder
    func tabIcon(for tab: Tab) -> some View {
        switch tab {
        case .synthesize:
            Image(systemName: "waveform")
        case .history:
            Image(systemName: "clock")
        case .models:
            Image(systemName: "cpu")
        case .logs:
            Image(systemName: "terminal")
        }
    }
}

struct SidebarView: View {
    @Binding var selectedTab: ContentView.Tab
    @EnvironmentObject var viewModel: TTSViewModel

    var body: some View {
        List(ContentView.Tab.allCases, id: \.self, selection: $selectedTab) { tab in
            Label {
                Text(tab.rawValue)
            } icon: {
                tabIcon(for: tab)
            }
            .tag(tab)
        }
        .listStyle(.sidebar)
        .frame(minWidth: 180)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                Divider()
                ServerControlView()
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
        }
    }

    @ViewBuilder
    func tabIcon(for tab: ContentView.Tab) -> some View {
        switch tab {
        case .synthesize:
            Image(systemName: "waveform")
        case .history:
            Image(systemName: "clock")
        case .models:
            Image(systemName: "cpu")
        case .logs:
            Image(systemName: "terminal")
        }
    }
}

struct ServerControlView: View {
    @EnvironmentObject var viewModel: TTSViewModel

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Circle()
                    .fill(viewModel.isServerRunning ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                Text(viewModel.isServerRunning ? "Server Running" : "Server Stopped")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }

            Button {
                Task {
                    if viewModel.isServerRunning {
                        viewModel.stopServer()
                    } else {
                        await viewModel.startServer()
                    }
                }
            } label: {
                HStack {
                    Image(systemName: viewModel.isServerRunning ? "stop.fill" : "play.fill")
                    Text(viewModel.isServerRunning ? "Stop" : "Start")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(viewModel.isServerRunning ? .red : .green)
            .disabled(viewModel.isLoading)
        }
    }
}

struct ServerStatusView: View {
    @EnvironmentObject var viewModel: TTSViewModel

    var body: some View {
        HStack(spacing: 4) {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(0.7)
            } else {
                Circle()
                    .fill(viewModel.isServerRunning ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
            }

            if let model = viewModel.serverManager.currentModel {
                Text(model.components(separatedBy: "/").last ?? model)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(TTSViewModel())
}
