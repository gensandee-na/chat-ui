import SwiftUI

struct ModelPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ModelPickerViewModel()

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.models) { model in
                    Button {
                        Task {
                            await viewModel.select(model.id)
                            dismiss()
                        }
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(model.displayName ?? model.name)
                                    .font(.headline)
                                if let description = model.description, !description.isEmpty {
                                    Text(description)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                            }
                            Spacer()
                            if viewModel.activeModelId == model.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.tint)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                }
            }
            .navigationTitle("Models")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .task { await viewModel.load() }
            .overlay {
                if let err = viewModel.error {
                    ContentUnavailableView(
                        "Couldn't load models",
                        systemImage: "exclamationmark.triangle",
                        description: Text(err))
                }
            }
        }
    }
}

@Observable
@MainActor
final class ModelPickerViewModel {
    private(set) var models: [ModelInfo] = []
    private(set) var activeModelId: String?
    private(set) var error: String?

    func load() async {
        do {
            async let modelsCall = HFClient.shared.listModels()
            async let settingsCall = HFClient.shared.userSettings()
            self.models = try await modelsCall
            self.activeModelId = try await settingsCall.activeModel
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    func select(_ id: String) async {
        do {
            var settings = try await HFClient.shared.userSettings()
            settings.activeModel = id
            _ = try await HFClient.shared.updateUserSettings(settings)
            activeModelId = id
        } catch {
            self.error = error.localizedDescription
        }
    }
}
