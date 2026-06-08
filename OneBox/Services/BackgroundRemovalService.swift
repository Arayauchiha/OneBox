import SwiftUI
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

/// A high-performance service for performing background removal locally on-device.
/// Utilizes the native Apple Vision Framework (VNGenerateForegroundInstanceMaskRequest).
enum BackgroundRemovalService {
    
    /// Removes the background from a UIImage and returns the result with transparency.
    static func removeBackground(from image: UIImage) async throws -> UIImage {
        guard let cgImage = image.cgImage else {
            throw NSError(domain: "BackgroundRemoval", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid image data."])
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNGenerateForegroundInstanceMaskRequest()
        
        // 1. Generate the foreground mask
        try requestHandler.perform([request])
        
        guard let result = request.results?.first else {
            throw NSError(domain: "BackgroundRemoval", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not identify subject."])
        }
        
        // 2. Extract the mask as a CVPixelBuffer
        let maskBuffer = try result.generateMaskedImage(
            ofInstances: result.allInstances,
            from: requestHandler,
            croppedToInstancesExtent: false
        )
        
        // 3. Convert the buffer to a UIImage
        let ciImage = CIImage(cvPixelBuffer: maskBuffer)
        let context = CIContext()
        guard let finalCgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            throw NSError(domain: "BackgroundRemoval", code: 3, userInfo: [NSLocalizedDescriptionKey: "Mask generation failed."])
        }
        
        return UIImage(cgImage: finalCgImage, scale: image.scale, orientation: image.imageOrientation)
    }
}
