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
        return controller
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {
        context.coordinator.url = url
        uiViewController.reloadData()
    }

    final class Coordinator: NSObject, QLPreviewControllerDataSource {
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
    }

    private final class PreviewItem: NSObject, QLPreviewItem {
        let previewItemURL: URL?

        init(previewURL: URL) {
            self.previewItemURL = previewURL
        }
    }
}
