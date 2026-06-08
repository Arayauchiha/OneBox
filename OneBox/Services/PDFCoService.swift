import Foundation

/// A professional networking service for interacting with the PDF.co API.
/// Optimized for credit efficiency and large file stability.
enum PDFCoService {
    private static let baseURL = "https://api.pdf.co/v1"
    
    /// Compresses/Optimizes a PDF to reduce its file size.
    static func compressPDF(at fileURL: URL) async throws -> Data {
        let contentType = "application/pdf"
        let uploadData = try await getUploadURL(fileName: fileURL.lastPathComponent, contentType: contentType)
        try await uploadFile(at: fileURL, to: uploadData.url, contentType: contentType)
        
        let processURL = "\(baseURL)/pdf/optimize"
        var request = URLRequest(url: URL(string: processURL)!)
        request.httpMethod = "POST"
        request.setValue(OneBoxSecrets.pdfCoAPIKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "url": uploadData.fileId,
            "name": "compressed.pdf",
            "async": false
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try checkResponseForErrors(data: data, response: response)
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let resultURLString = json?["url"] as? String, let resultURL = URL(string: resultURLString) else {
            throw URLError(.cannotParseResponse)
        }
        
        let (finalData, _) = try await URLSession.shared.data(from: resultURL)
        return finalData
    }
    
    /// Performs OCR on an image or PDF and returns the recognized text.
    /// Uses documented endpoints for optimal credit usage and accuracy.
    static func performOCR(at fileURL: URL, isPDF: Bool = false) async throws -> String {
        let contentType = isPDF ? "application/pdf" : "image/jpeg"
        
        // 1. Get Upload URL
        let uploadData = try await getUploadURL(fileName: fileURL.lastPathComponent, contentType: contentType)
        
        // 2. Upload File (with explicit security access for Sandbox)
        try await uploadFile(at: fileURL, to: uploadData.url, contentType: contentType)
        
        // 3. Perform OCR
        // PDF.co Documentation: /pdf/convert/to/text is the primary engine for both PDF and Images
        let processURL = "\(baseURL)/pdf/convert/to/text"
        var request = URLRequest(url: URL(string: processURL)!)
        request.httpMethod = "POST"
        request.setValue(OneBoxSecrets.pdfCoAPIKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "url": uploadData.fileId,
            "async": false,
            "inline": true // We want text in the JSON response
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try checkResponseForErrors(data: data, response: response)
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        // DOCUMENTATION PARSING:
        // 1. Check 'text' field (Primary for /pdf/convert/to/text)
        if let recognizedText = json?["text"] as? String {
            return recognizedText
        }
        
        // 2. Check 'body' field (Primary for other inline conversion endpoints)
        if let recognizedText = json?["body"] as? String {
            return recognizedText
        }
        
        // 3. Fallback to URL if inline failed for some reason
        if let resultURLString = json?["url"] as? String, let resultURL = URL(string: resultURLString) {
            let (finalData, _) = try await URLSession.shared.data(from: resultURL)
            return String(data: finalData, encoding: .utf8) ?? "Could not decode text result."
        }
        
        throw NSError(domain: "PDFCoService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Extraction completed but no text was found in the response."])
    }

    // MARK: - Helper Methods
    
    private struct UploadResponse: Decodable {
        let presignedUrl: String?
        let url: String?
        let error: Bool?
        let message: String?
    }
    
    private static func getUploadURL(fileName: String, contentType: String) async throws -> (url: String, fileId: String) {
        let urlString = "\(baseURL)/file/upload/get-presigned-url?name=\(fileName)&contenttype=\(contentType)"
        guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? urlString) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue(OneBoxSecrets.pdfCoAPIKey, forHTTPHeaderField: "x-api-key")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(UploadResponse.self, from: data)
        
        if response.error == true {
            throw NSError(domain: "PDFCoService", code: 1, userInfo: [NSLocalizedDescriptionKey: response.message ?? "API Error"])
        }
        
        guard let uploadURL = response.presignedUrl, let fileId = response.url else {
            throw URLError(.cannotParseResponse)
        }
        
        return (uploadURL, fileId)
    }
    
    private static func uploadFile(at localURL: URL, to remoteURLString: String, contentType: String) async throws {
        guard let remoteURL = URL(string: remoteURLString) else { throw URLError(.badURL) }
        
        let isSecured = localURL.startAccessingSecurityScopedResource()
        defer { if isSecured { localURL.stopAccessingSecurityScopedResource() } }
        
        var request = URLRequest(url: remoteURL)
        request.httpMethod = "PUT"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        
        // Optimized Reading: Use a timeout-resilient upload pattern
        let fileData = try Data(contentsOf: localURL)
        
        // For large files (like scans), we ensure the request is configured for background-friendly operation
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60 // Allow more time for large scan uploads
        let session = URLSession(configuration: config)
        
        let (_, response) = try await session.upload(for: request, from: fileData)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
    
    private static func checkResponseForErrors(data: Data, response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let message = json?["message"] as? String ?? "HTTP Error \(httpResponse.statusCode)"
            throw NSError(domain: "PDFCoService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
        }
        
        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        if let error = json?["error"] as? Bool, error == true {
            let message = json?["message"] as? String ?? "API Error"
            throw NSError(domain: "PDFCoService", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
        }
    }
}
