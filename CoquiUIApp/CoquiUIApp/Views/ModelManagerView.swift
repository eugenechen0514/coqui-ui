import SwiftUI

struct ModelManagerView: View {
    @EnvironmentObject var viewModel: TTSViewModel
    @State private var selectedCategory: ModelCategory = .all
    @State private var searchText = ""

    enum ModelCategory: String, CaseIterable {
        case all = "All"
        case english = "English"
        case multilingual = "Multilingual"
        case chinese = "Chinese"
        case other = "Other"
    }

    var filteredModels: [String] {
        var models = viewModel.availableModels

        // Filter by search
        if !searchText.isEmpty {
            models = models.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }

        // Filter by category
        switch selectedCategory {
        case .all:
            break
        case .english:
            models = models.filter { $0.contains("/en/") }
        case .multilingual:
            models = models.filter { $0.contains("multilingual") }
        case .chinese:
            models = models.filter { $0.contains("/zh/") || $0.contains("chinese") }
        case .other:
            models = models.filter { !$0.contains("/en/") && !$0.contains("multilingual") && !$0.contains("/zh/") }
        }

        return models
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Model Manager")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button {
                    Task { await viewModel.loadModels() }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }
            .padding()

            Divider()

            // Category picker
            Picker("Category", selection: $selectedCategory) {
                ForEach(ModelCategory.allCases, id: \.self) { category in
                    Text(category.rawValue).tag(category)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)

            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search models...", text: $searchText)
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
            .padding(.bottom, 8)

            // Models list
            if filteredModels.isEmpty {
                EmptyModelsView()
            } else {
                List(filteredModels, id: \.self, selection: $viewModel.selectedModel) { model in
                    ModelRow(model: model, isSelected: model == viewModel.selectedModel)
                }
                .listStyle(.inset)
            }

            Divider()

            // Current model info
            CurrentModelInfoBar()
        }
    }
}

struct ModelRow: View {
    let model: String
    let isSelected: Bool

    var modelInfo: (name: String, language: String, type: String) {
        let components = model.components(separatedBy: "/")
        let name = components.last ?? model
        let language = components.count > 1 ? components[1] : "unknown"
        let type = components.count > 3 ? components[3] : "unknown"
        return (name, language, type)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(modelInfo.name)
                    .fontWeight(.medium)

                HStack(spacing: 8) {
                    Label(modelInfo.language.uppercased(), systemImage: "globe")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Label(modelInfo.type, systemImage: "cpu")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.accentColor)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

struct CurrentModelInfoBar: View {
    @EnvironmentObject var viewModel: TTSViewModel

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Current Model")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(viewModel.selectedModel.components(separatedBy: "/").last ?? viewModel.selectedModel)
                    .font(.footnote)
                    .fontWeight(.medium)
            }

            Spacer()

            if viewModel.isServerRunning && viewModel.serverManager.currentModel != viewModel.selectedModel {
                Button("Apply") {
                    Task {
                        try? await viewModel.serverManager.restartServer(model: viewModel.selectedModel)
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
    }
}

struct EmptyModelsView: View {
    @EnvironmentObject var viewModel: TTSViewModel

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "cpu")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No models found")
                .font(.title3)
                .foregroundColor(.secondary)

            if !viewModel.isServerRunning {
                Text("Start the server to load available models")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button("Start Server") {
                    Task { await viewModel.startServer() }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ModelManagerView()
        .environmentObject(TTSViewModel())
        .frame(width: 500, height: 400)
}
