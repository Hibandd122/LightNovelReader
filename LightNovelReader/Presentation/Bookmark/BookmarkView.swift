import SwiftUI

public struct BookmarkView: View {
    public init() {}
    
    public var body: some View {
        NavigationView {
            List {
                Text("No bookmarks yet.")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Bookmarks")
        }
    }
}
