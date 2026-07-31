import SwiftUI

public enum AppThemeType: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    case oled = "OLED Dark"
    case sepia = "Sepia"
    case warm = "Warm Paper"
    case night = "Night Shift"
    
    public var id: String { self.rawValue }
}

public struct ThemeConfig {
    public var backgroundColor: UIColor
    public var textColor: UIColor
    public var accentColor: UIColor
    public var selectionColor: UIColor
}

public final class ThemeEngine: ObservableObject {
    @Published public var currentThemeType: AppThemeType = .system
    
    public init() {}
    
    public var currentConfig: ThemeConfig {
        switch currentThemeType {
        case .system:
            // Use UITraitCollection.current in real implementation
            return ThemeConfig(backgroundColor: .systemBackground, textColor: .label, accentColor: .systemBlue, selectionColor: .systemYellow)
        case .light:
            return ThemeConfig(backgroundColor: .white, textColor: .black, accentColor: .systemBlue, selectionColor: UIColor.yellow.withAlphaComponent(0.3))
        case .dark:
            return ThemeConfig(backgroundColor: UIColor(white: 0.1, alpha: 1.0), textColor: UIColor(white: 0.9, alpha: 1.0), accentColor: .systemBlue, selectionColor: UIColor.yellow.withAlphaComponent(0.3))
        case .oled:
            return ThemeConfig(backgroundColor: .black, textColor: .lightGray, accentColor: .systemPurple, selectionColor: UIColor.purple.withAlphaComponent(0.3))
        case .sepia:
            return ThemeConfig(backgroundColor: UIColor(red: 0.94, green: 0.92, blue: 0.88, alpha: 1.0), textColor: UIColor(red: 0.2, green: 0.15, blue: 0.1, alpha: 1.0), accentColor: .systemBrown, selectionColor: UIColor.orange.withAlphaComponent(0.3))
        case .warm:
            return ThemeConfig(backgroundColor: UIColor(red: 1.0, green: 0.98, blue: 0.94, alpha: 1.0), textColor: UIColor(red: 0.3, green: 0.25, blue: 0.2, alpha: 1.0), accentColor: .systemOrange, selectionColor: UIColor.orange.withAlphaComponent(0.3))
        case .night:
            return ThemeConfig(backgroundColor: UIColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 1.0), textColor: UIColor(red: 0.8, green: 0.8, blue: 0.85, alpha: 1.0), accentColor: .systemIndigo, selectionColor: UIColor.systemIndigo.withAlphaComponent(0.3))
        }
    }
}