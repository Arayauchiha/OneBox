import Foundation

/// A professional way to manage API keys and environment-specific settings.
/// This implementation reads from a local `Secrets.plist` which is ignored by git.
enum OneBoxSecrets {
    
    private static var secrets: [String: Any]? {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let xml = FileManager.default.contents(atPath: path) else {
            return nil
        }
        return (try? PropertyListSerialization.propertyList(from: xml, options: .mutableContainersAndLeaves, format: nil)) as? [String: Any]
    }
    
    /// PDF.co API Key
    /// Sign up for a key at https://pdf.co/
    static var pdfCoAPIKey: String {
        return secrets?["PDFCO_API_KEY"] as? String ?? ""
    }
    
    static var hasValidPDFCoKey: Bool {
        let key = pdfCoAPIKey
        return !key.isEmpty && key != "YOUR_API_KEY_HERE" && key != "PASTE_YOUR_KEY_HERE"
    }
}
