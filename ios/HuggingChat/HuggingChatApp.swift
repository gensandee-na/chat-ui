import SwiftUI

@main
struct HuggingChatApp: App {
    @State private var auth = AuthState()
    @State private var router = AppRouter()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(auth)
                .environment(router)
                .task { await auth.refresh() }
        }
    }
}

/// Top-level switcher: shows the sign-in wall or the main tab interface based
/// on the cookie-driven `AuthState`.
struct RootView: View {
    @Environment(AuthState.self) private var auth

    var body: some View {
        Group {
            if auth.isLoggedIn {
                RootTabView()
            } else {
                SignInWallView()
            }
        }
    }
}

struct SignInWallView: View {
    @Environment(AuthState.self) private var auth
    @State private var coordinator = LoginCoordinator()
    @State private var error: String?

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
            Text("HuggingChat").font(.largeTitle).bold()
            Text("Sign in to start chatting.")
                .foregroundStyle(.secondary)
            Spacer()
            Button {
                Task {
                    do {
                        try await coordinator.start()
                        await auth.refresh()
                    } catch {
                        self.error = error.localizedDescription
                    }
                }
            } label: {
                Text("Sign in")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 24)
            if let error {
                Text(error).font(.footnote).foregroundStyle(.red)
            }
        }
        .padding()
    }
}
