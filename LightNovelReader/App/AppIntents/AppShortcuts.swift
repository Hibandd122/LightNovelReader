import AppIntents

public struct LightNovelAppShortcuts: AppShortcutsProvider {
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ReadNovelIntent(),
            phrases: [
                "Read my light novel in \(.applicationName)",
                "Continue reading in \(.applicationName)",
                "Play \(.applicationName)"
            ],
            shortTitle: "Read Novel",
            systemImageName: "book"
        )
    }
}
