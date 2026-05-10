import SwiftUI

struct SettingsView: View {
    @Environment(AuthState.self) private var auth
    @Environment(AppRouter.self) private var router
    @State private var viewModel = SettingsViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    if let user = viewModel.user {
                        LabeledContent("Username", value: user.username ?? "—")
                        if let email = user.email { LabeledContent("Email", value: email) }
                    } else {
                        ProgressView()
                    }
                    Button("Sign out", role: .destructive) {
                        Task {
                            try? await HFClient.shared.signOut()
                            await auth.signOut()
                        }
                    }
                }

                Section("Chat") {
                    Button("Change model") { router.presentedModelPicker = true }
                    if let settings = viewModel.settings {
                        Toggle(
                            "Haptics",
                            isOn: Binding(
                                get: { settings.hapticsEnabled ?? true },
                                set: { viewModel.setHapticsEnabled($0) }
                            ))
                        Picker(
                            "Streaming",
                            selection: Binding(
                                get: { settings.streamingMode ?? "smooth" },
                                set: { viewModel.setStreamingMode($0) }
                            )
                        ) {
                            Text("Smooth").tag("smooth")
                            Text("Raw").tag("raw")
                        }
                    }
                }

                Section("About") {
                    LabeledContent(
                        "Version",
                        value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
                            ?? "—")
                    LabeledContent("Origin", value: AppConfig.baseURL.absoluteString)
                }
            }
            .navigationTitle("Settings")
            .task { await viewModel.load() }
        }
    }
}

@Observable
@MainActor
final class SettingsViewModel {
    private(set) var user: UserInfo?
    private(set) var settings: UserSettings?
    private(set) var error: String?

    func load() async {
        do {
            async let u = HFClient.shared.currentUser()
            async let s = HFClient.shared.userSettings()
            self.user = try await u
            self.settings = try await s
        } catch {
            self.error = error.localizedDescription
        }
    }

    func setHapticsEnabled(_ on: Bool) {
        guard var current = settings else { return }
        current.hapticsEnabled = on
        settings = current
        Task { _ = try? await HFClient.shared.updateUserSettings(current) }
    }

    func setStreamingMode(_ mode: String) {
        guard var current = settings else { return }
        current.streamingMode = mode
        settings = current
        Task { _ = try? await HFClient.shared.updateUserSettings(current) }
    }
}
