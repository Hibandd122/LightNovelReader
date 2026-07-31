import SwiftUI

public struct SearchView: View {
    @State private var searchText = ""
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            VStack {
                Text("Search functionality coming soon.")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Search")
            .searchable(text: $searchText, prompt: "Search novels or text...")
        }
    }
}
