import QuickLook
import SwiftUI

struct QuickLookDocumentPreview: UIViewControllerRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {
        context.coordinator.url = url
        uiViewController.reloadData()
    }

    final class Coordinator: NSObject, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
        var url: URL

        init(url: URL) {
            self.url = url
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            FileManager.default.fileExists(atPath: url.path) ? 1 : 0
        }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            PreviewItem(previewURL: url)
        }

        func previewController(_ controller: QLPreviewController, editingModeFor previewItem: any QLPreviewItem) -> QLPreviewItemEditingMode {
            .createCopy
        }

        func previewController(_ controller: QLPreviewController, didUpdateContentsOf previewItem: any QLPreviewItem) {
            guard let updatedURL = previewItem.previewItemURL else { return }
            url = updatedURL
        }

        func previewController(_ controller: QLPreviewController, didSaveEditedCopyOf previewItem: any QLPreviewItem, at modifiedContentsURL: URL) {
            url = modifiedContentsURL
        }
    }

    private final class PreviewItem: NSObject, QLPreviewItem {
        let previewItemURL: URL?

        init(previewURL: URL) {
            self.previewItemURL = previewURL
        }
    }
}
