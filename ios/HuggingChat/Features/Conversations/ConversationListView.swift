import SwiftUI

struct ConversationListView: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel = ConversationListViewModel()

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.items) { item in
                    Button {
                        router.openConversation(item.id)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(item.title.isEmpty ? "New chat" : item.title)
                                .font(.body)
                                .lineLimit(1)
                            Text(item.updatedAt, style: .relative)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            Task { await viewModel.delete(id: item.id) }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }

                if viewModel.hasMore && !viewModel.items.isEmpty {
                    Button("Load more") {
                        Task { await viewModel.loadMore() }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            if let id = await viewModel.createNew() {
                                router.openConversation(id)
                            }
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("New chat")
                }
            }
            .refreshable { await viewModel.refresh() }
            .task { await viewModel.refresh() }
            .overlay {
                if let err = viewModel.error {
                    ContentUnavailableView(
                        "Couldn't load",
                        systemImage: "exclamationmark.triangle",
                        description: Text(err))
                }
            }
        }
    }
}

@Observable
@MainActor
final class ConversationListViewModel {
    private(set) var items: [ConversationListItem] = []
    private(set) var hasMore: Bool = false
    private(set) var error: String?
    private var nextPage: Int = 0

    func refresh() async {
        nextPage = 0
        items = []
        await loadMore()
    }

    func loadMore() async {
        do {
            let resp = try await HFClient.shared.listConversations(page: nextPage)
            items.append(contentsOf: resp.conversations)
            hasMore = resp.hasMore
            nextPage += 1
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    func delete(id: String) async {
        do {
            try await HFClient.shared.deleteConversation(id: id)
            items.removeAll { $0.id == id }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func createNew() async -> String? {
        do {
            let resp = try await HFClient.shared.createConversation(
                CreateConversationRequest(title: nil, model: nil))
            await refresh()
            return resp.conversationId
        } catch {
            self.error = error.localizedDescription
            return nil
        }
    }
}
