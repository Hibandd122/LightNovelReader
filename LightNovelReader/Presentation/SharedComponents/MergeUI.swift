import SwiftUI

public struct MergeUI: View {
    public let localText: String
    public let remoteText: String
    public var onResolve: (String) -> Void
    
    @State private var selectedVersion: Int? = nil // 0 for local, 1 for remote
    
    public init(localText: String, remoteText: String, onResolve: @escaping (String) -> Void) {
        self.localText = localText
        self.remoteText = remoteText
        self.onResolve = onResolve
    }
    
    public var body: some View {
        VStack {
            Text("Conflict Detected")
                .font(.title)
                .padding()
            
            Text("The document was modified on another device. Please choose which version to keep.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            HStack(spacing: 16) {
                VStack {
                    Text("Local Device")
                        .font(.headline)
                    
                    ScrollView {
                        Text(localText)
                            .padding()
                    }
                    .background(selectedVersion == 0 ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                    .border(selectedVersion == 0 ? Color.blue : Color.clear, width: 2)
                    .onTapGesture {
                        selectedVersion = 0
                    }
                }
                
                VStack {
                    Text("Cloud (Google Docs)")
                        .font(.headline)
                    
                    ScrollView {
                        Text(remoteText)
                            .padding()
                    }
                    .background(selectedVersion == 1 ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
                    .border(selectedVersion == 1 ? Color.green : Color.clear, width: 2)
                    .onTapGesture {
                        selectedVersion = 1
                    }
                }
            }
            .padding()
            
            Button("Confirm Selection") {
                if let selected = selectedVersion {
                    onResolve(selected == 0 ? localText : remoteText)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedVersion == nil)
            .padding()
        }
    }
}
