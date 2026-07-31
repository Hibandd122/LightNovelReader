import Foundation
import UIKit

public struct HighlightEngine {
    public let defaultHighlightColor = UIColor.systemYellow.withAlphaComponent(0.3)
    
    public init() {}
    
    /// Applies highlight attributes to a specific range in an NSAttributedString
    public func applyHighlight(to baseText: NSAttributedString, at range: NSRange, color: UIColor? = nil) -> NSAttributedString {
        let mutableString = NSMutableAttributedString(attributedString: baseText)
        
        // Clear previous highlights if needed
        mutableString.removeAttribute(.backgroundColor, range: NSRange(location: 0, length: mutableString.length))
        
        // Apply new highlight
        mutableString.addAttribute(.backgroundColor, value: color ?? defaultHighlightColor, range: range)
        
        return mutableString
    }
}
