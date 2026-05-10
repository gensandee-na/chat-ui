import Foundation
import PhotosUI
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct PickedFile {
    let name: String
    let mime: String
    let base64: String
}

/// Presents either a `PHPicker` (when the accept hint requests images) or a
/// `UIDocumentPicker` for any-MIME selection. Encodes the picked files as
/// base64 strings ready for the WebView bridge to decode back into `File`
/// objects.
@MainActor
final class FilePickerCoordinator: NSObject {
    private var continuation: CheckedContinuation<[PickedFile], Error>?

    func pickFiles(accept: String, multiple: Bool) async throws -> [PickedFile] {
        try await withCheckedThrowingContinuation { cont in
            self.continuation = cont
            if accept.contains("image") {
                presentPhotoPicker(multiple: multiple)
            } else {
                presentDocumentPicker(accept: accept, multiple: multiple)
            }
        }
    }

    // MARK: - Presentation helpers

    private var topViewController: UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController?
            .topMostPresented()
    }

    private func presentPhotoPicker(multiple: Bool) {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = multiple ? 0 : 1
        config.filter = .images

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        topViewController?.present(picker, animated: true)
    }

    private func presentDocumentPicker(accept: String, multiple: Bool) {
        let types = utTypes(forAccept: accept)
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: true)
        picker.allowsMultipleSelection = multiple
        picker.delegate = self
        topViewController?.present(picker, animated: true)
    }

    private func utTypes(forAccept accept: String) -> [UTType] {
        let parts = accept.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        let mapped: [UTType] = parts.compactMap { entry in
            if entry.hasPrefix(".") {
                return UTType(filenameExtension: String(entry.dropFirst()))
            }
            if entry.contains("/") {
                return UTType(mimeType: entry)
            }
            return nil
        }
        return mapped.isEmpty ? [.data] : mapped
    }

    private func resume(with files: [PickedFile]) {
        continuation?.resume(returning: files)
        continuation = nil
    }

    private func resume(throwing error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
}

extension FilePickerCoordinator: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        Task {
            var picked: [PickedFile] = []
            for result in results {
                if let file = await Self.pickedFile(from: result.itemProvider) {
                    picked.append(file)
                }
            }
            await MainActor.run { self.resume(with: picked) }
        }
    }

    private static func pickedFile(from provider: NSItemProvider) async -> PickedFile? {
        let suggestedName = provider.suggestedName ?? "image"
        for type in [UTType.png, UTType.jpeg, UTType.heic, UTType.image] {
            if provider.hasItemConformingToTypeIdentifier(type.identifier) {
                if let data = await loadData(provider: provider, type: type) {
                    let mime = type.preferredMIMEType ?? "application/octet-stream"
                    let ext = type.preferredFilenameExtension ?? "bin"
                    return PickedFile(
                        name: "\(suggestedName).\(ext)",
                        mime: mime,
                        base64: data.base64EncodedString()
                    )
                }
            }
        }
        return nil
    }

    private static func loadData(provider: NSItemProvider, type: UTType) async -> Data? {
        await withCheckedContinuation { cont in
            provider.loadDataRepresentation(forTypeIdentifier: type.identifier) { data, _ in
                cont.resume(returning: data)
            }
        }
    }
}

extension FilePickerCoordinator: UIDocumentPickerDelegate {
    func documentPicker(
        _ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]
    ) {
        controller.dismiss(animated: true)
        var picked: [PickedFile] = []
        for url in urls {
            let didStart = url.startAccessingSecurityScopedResource()
            defer { if didStart { url.stopAccessingSecurityScopedResource() } }
            guard let data = try? Data(contentsOf: url) else { continue }
            let mime =
                UTType(filenameExtension: url.pathExtension)?.preferredMIMEType
                ?? "application/octet-stream"
            picked.append(
                PickedFile(name: url.lastPathComponent, mime: mime, base64: data.base64EncodedString())
            )
        }
        resume(with: picked)
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true)
        resume(with: [])
    }
}

private extension UIViewController {
    func topMostPresented() -> UIViewController {
        var current = self
        while let presented = current.presentedViewController {
            current = presented
        }
        return current
    }
}
