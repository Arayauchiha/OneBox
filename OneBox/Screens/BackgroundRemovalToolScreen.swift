import SwiftUI
import PhotosUI

struct BackgroundRemovalToolScreen: View {
    @State private var photoSelection: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var resultImage: UIImage?
    @State private var isProcessing = false
    @State private var statusMessage = "Select an image to remove its background."
    
    // Support for pre-selected items from Home Screen
    private var initialItems: [ImportSelectionItem]?
    
    init(initialItems: [ImportSelectionItem]? = nil) {
        self.initialItems = initialItems
    }
    
    private let cardCornerRadius: CGFloat = 24

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                inputCard
                
                if let image = selectedImage {
                    previewCard(image)
                    actionCard
                }
                
                if let result = resultImage {
                    resultCard(result)
                }
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Background Remover")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadInitialItems()
        }
        .onChange(of: photoSelection) { _, newItem in
            Task {
                await handlePhotoSelection(newItem)
            }
        }
    }

    // MARK: - UI Components

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Import Photo")
                .font(.headline)

            PhotosPicker(selection: $photoSelection, matching: .images) {
                Label("Choose from Library", systemImage: "photo.on.rectangle")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.accentColor.opacity(0.1))
                    .foregroundStyle(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .cardContainer(cornerRadius: cardCornerRadius)
    }

    private func previewCard(_ image: UIImage) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Source Image")
                .font(.headline)
            
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 250)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .frame(maxWidth: .infinity)
        }
        .cardContainer(cornerRadius: cardCornerRadius)
    }

    private var actionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI Removal")
                .font(.headline)
            
            Text(statusMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                Task {
                    await performRemoval()
                }
            } label: {
                HStack {
                    if isProcessing {
                        ProgressView().tint(.white).padding(.trailing, 8)
                    }
                    Text(isProcessing ? "Lifting Subject..." : "Remove Background")
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
            }
            .applyGlassStyle(prominent: true)
            .disabled(isProcessing)
        }
        .cardContainer(cornerRadius: cardCornerRadius)
    }

    private func resultCard(_ image: UIImage) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Result")
                    .font(.headline)
                
                Spacer()
                
                // Native iOS 17+ ShareLink for "Save Image" support
                ShareLink(item: Image(uiImage: image), preview: SharePreview("Removed Background", image: Image(uiImage: image))) {
                    Label("Save/Share", systemImage: "square.and.arrow.up")
                        .font(.caption.weight(.semibold))
                }
                .applyGlassStyle(prominent: false)
            }
            
            ZStack {
                // Transparency Checkerboard Pattern
                Image("Checkerboard") 
                    .resizable(resizingMode: .tile)
                    .opacity(0.1)
                
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
            }
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .frame(maxWidth: .infinity)
        }
        .cardContainer(cornerRadius: cardCornerRadius)
    }

    // MARK: - Logic Helpers

    private func loadInitialItems() {
        guard let items = initialItems, !items.isEmpty, selectedImage == nil else { return }
        
        if let first = items.first {
            if let image = first.previewImage {
                self.selectedImage = image
                self.statusMessage = "Ready to lift subject."
                self.resultImage = nil
            } else if let url = first.fileURL {
                // Handle security-scoped URLs for Files app imports
                let isAccessing = url.startAccessingSecurityScopedResource()
                defer { if isAccessing { url.stopAccessingSecurityScopedResource() } }
                
                if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                    self.selectedImage = image
                    self.statusMessage = "Ready to lift subject."
                    self.resultImage = nil
                }
            }
        }
    }

    private func handlePhotoSelection(_ item: PhotosPickerItem?) async {
        guard let item = item else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            await MainActor.run {
                selectedImage = image
                resultImage = nil
                statusMessage = "Ready to lift subject."
            }
        }
    }

    private func performRemoval() async {
        guard let image = selectedImage else { return }
        
        await MainActor.run {
            isProcessing = true
            statusMessage = "Analyzing image contours..."
        }
        
        do {
            let result = try await BackgroundRemovalService.removeBackground(from: image)
            await MainActor.run {
                resultImage = result
                isProcessing = false
                statusMessage = "Background removed successfully!"
            }
        } catch {
            await MainActor.run {
                isProcessing = false
                statusMessage = "Failed: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Native Styling Helpers
extension View {
    @ViewBuilder
    func applyGlassStyle(prominent: Bool) -> some View {
        if prominent {
            self.buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .controlSize(.large)
        } else {
            self.buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .controlSize(.regular)
        }
    }
}

// Re-using cardContainer extension
private extension View {
    func cardContainer(cornerRadius: CGFloat) -> some View {
        self
            .padding(16)
            .background(
                Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
    }
}
