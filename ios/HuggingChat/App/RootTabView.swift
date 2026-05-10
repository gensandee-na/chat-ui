import SwiftUI

struct RootTabView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var router = router
        TabView(selection: $router.selectedTab) {
            ChatHostView()
                .tabItem { Label("Chat", systemImage: "bubble.left.fill") }
                .tag(AppRouter.Tab.chat)

            ConversationListView()
                .tabItem { Label("History", systemImage: "list.bullet") }
                .tag(AppRouter.Tab.conversations)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(AppRouter.Tab.settings)
        }
        .sheet(isPresented: $router.presentedModelPicker) {
            ModelPickerSheet()
        }
    }
}

/// Host for the WKWebView. Watches the router's currentConversationId and
/// reloads the embed URL when it changes.
struct ChatHostView: View {
    @Environment(AppRouter.self) private var router
    @Environment(AuthState.self) private var auth

    var body: some View {
        NavigationStack {
            ChatWebView(conversationId: router.currentConversationId)
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle(navigationTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            router.newConversation()
                        } label: {
                            Image(systemName: "square.and.pencil")
                        }
                        .accessibilityLabel("New chat")
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        if let id = router.currentConversationId {
                            Button {
                                router.presentedShareConversationId = id
                            } label: {
                                Image(systemName: "square.and.arrow.up")
                            }
                            .accessibilityLabel("Share")
                        }
                    }
                }
                .sheet(item: shareBinding) { item in
                    ShareCoordinator(conversationId: item.id)
                }
        }
    }

    private var navigationTitle: String {
        router.currentConversationId == nil ? "New chat" : "Chat"
    }

    private var shareBinding: Binding<ShareItem?> {
        Binding(
            get: { router.presentedShareConversationId.map(ShareItem.init) },
            set: { router.presentedShareConversationId = $0?.id }
        )
    }
}

private struct ShareItem: Identifiable, Hashable { let id: String }
