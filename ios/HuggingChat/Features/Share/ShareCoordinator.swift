import SwiftUI
import UIKit

/// Calls `POST /conversation/{id}/share`, then presents the system share sheet
/// with the returned URL.
struct ShareCoordinator: View {
    let conversationId: String

    @Environment(\.dismiss) private var dismiss
    @State private var url: URL?
    @State private var error: String?

    var body: some View {
        Group {
            if let url {
                ShareSheet(items: [url])
                    .ignoresSafeArea()
            } else if let error {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                    Text(error)
                    Button("Close") { dismiss() }
                }
                .padding()
            } else {
                ProgressView()
                    .task { await prepare() }
            }
        }
    }

    private func prepare() async {
        do {
            let result = try await HFClient.shared.share(conversationId: conversationId)
            self.url =
                URL(string: result)
                ?? AppConfig.baseURL.appendingPathComponent("r").appendingPathComponent(result)
        } catch {
            self.error = error.localizedDescription
        }
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context _: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_: UIActivityViewController, context _: Context) {}
}
