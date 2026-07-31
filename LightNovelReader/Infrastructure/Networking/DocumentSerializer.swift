import Foundation

/// Serializes local diffs or text edits into Google Docs `BatchUpdate` requests.
public struct DocumentSerializer {
    public init() {}
    
    /// Converts a simple string insertion into a Google Docs request.
    public func serializeInsertion(text: String, at index: Int) -> GoogleDocsRequest {
        let insertRequest = InsertTextRequest(text: text, location: Location(index: index))
        return GoogleDocsRequest(insertText: insertRequest, deleteContentRange: nil)
    }
    
    /// Converts a simple string deletion into a Google Docs request.
    public func serializeDeletion(startIndex: Int, endIndex: Int) -> GoogleDocsRequest {
        let deleteRequest = DeleteContentRangeRequest(range: RangeElement(startIndex: startIndex, endIndex: endIndex))
        return GoogleDocsRequest(insertText: nil, deleteContentRange: deleteRequest)
    }
    
    /// Complex diffing (Myers Diff) would sit here to compare two strings and output multiple GoogleDocsRequests.
    public func computeDiffAndSerialize(oldText: String, newText: String) -> [GoogleDocsRequest] {
        // Stub for advanced Diff algorithm -> BatchUpdate requests
        var requests = [GoogleDocsRequest]()
        
        // For demonstration, if we just appended text:
        if newText.hasPrefix(oldText) {
            let appended = String(newText.dropFirst(oldText.count))
            requests.append(serializeInsertion(text: appended, at: oldText.count + 1)) // Docs indices offset by 1
        } else {
            // Full replacement (Not recommended in production, just a fallback)
            requests.append(serializeDeletion(startIndex: 1, endIndex: oldText.count + 1))
            requests.append(serializeInsertion(text: newText, at: 1))
        }
        
        return requests
    }
}
