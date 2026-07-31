import UIKit
import CoreText

public final class FontManager {
    public static let shared = FontManager()
    
    private var registeredFonts: Set<String> = []
    
    private init() {}
    
    public func getFont(name: String, size: CGFloat, weight: UIFont.Weight) -> UIFont {
        if name == "System" {
            return UIFont.systemFont(ofSize: size, weight: weight)
        }
        
        if let font = UIFont(name: name, size: size) {
            return font
        }
        
        // Fallback
        return UIFont.systemFont(ofSize: size, weight: weight)
    }
    
    /// Imports a custom font from a TTF/OTF file path
    public func importFont(from url: URL) throws {
        guard let fontDataProvider = CGDataProvider(url: url as CFURL) else {
            throw NSError(domain: "FontManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid font file"])
        }
        
        guard let font = CGFont(fontDataProvider) else {
            throw NSError(domain: "FontManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not create CGFont"])
        }
        
        var error: Unmanaged<CFError>?
        if !CTFontManagerRegisterGraphicsFont(font, &error) {
            let errorDescription = error?.takeRetainedValue().localizedDescription ?? "Unknown error"
            throw NSError(domain: "FontManager", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to register font: \(errorDescription)"])
        }
        
        if let fontName = font.postScriptName as String? {
            registeredFonts.insert(fontName)
        }
    }
}
