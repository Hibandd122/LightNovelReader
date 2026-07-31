import UIKit
import CoreText

public struct TypographySettings: Equatable {
    public var fontFamily: String
    public var fontSize: CGFloat
    public var fontWeight: UIFont.Weight
    public var lineHeightMultiple: CGFloat
    public var paragraphSpacing: CGFloat
    public var wordSpacing: CGFloat
    public var letterSpacing: CGFloat
    public var hyphenationFactor: Float
    public var margins: UIEdgeInsets
    
    public static let defaultSettings = TypographySettings(
        fontFamily: "System",
        fontSize: 18.0,
        fontWeight: .regular,
        lineHeightMultiple: 1.5,
        paragraphSpacing: 16.0,
        wordSpacing: 0.0,
        letterSpacing: 0.0,
        hyphenationFactor: 1.0,
        margins: UIEdgeInsets(top: 40, left: 20, bottom: 40, right: 20)
    )
}

public struct TypographyEngine {
    public init() {}
    
    public func applyTypography(to text: String, settings: TypographySettings, fontManager: FontManager) -> NSAttributedString {
        let font = fontManager.getFont(name: settings.fontFamily, size: settings.fontSize, weight: settings.fontWeight)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = settings.lineHeightMultiple
        paragraphStyle.paragraphSpacing = settings.paragraphSpacing
        paragraphStyle.hyphenationFactor = settings.hyphenationFactor
        paragraphStyle.alignment = .justified
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraphStyle,
            .kern: settings.letterSpacing,
            // wordSpacing requires custom CoreText manipulation usually, omitted for brevity
        ]
        
        return NSAttributedString(string: text, attributes: attributes)
    }
}
