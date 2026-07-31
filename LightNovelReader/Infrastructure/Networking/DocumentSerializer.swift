import Foundation

/// Serializes local diffs or text edits into Google Docs `BatchUpdate` requests.
public struct DocumentSerializer {
    public init() {}
    
    /// Converts a simple string insertion into a Google Docs request.
    public func serializeInsertion(text: String, at index: Int, tabID: String? = nil) -> GoogleDocsRequest {
        let insertRequest = InsertTextRequest(text: text, location: Location(index: index, tabId: tabID))
        return GoogleDocsRequest(insertText: insertRequest, deleteContentRange: nil)
    }
    
    /// Converts a simple string deletion into a Google Docs request.
    public func serializeDeletion(startIndex: Int, endIndex: Int, tabID: String? = nil) -> GoogleDocsRequest {
        let deleteRequest = DeleteContentRangeRequest(range: RangeElement(startIndex: startIndex, endIndex: endIndex, tabId: tabID))
        return GoogleDocsRequest(insertText: nil, deleteContentRange: deleteRequest)
    }
    
    public func computeDiffAndSerialize(oldText: String, newText: String) -> [GoogleDocsRequest] {
        let oldUnits = Array(oldText.utf16)
        let newUnits = Array(newText.utf16)
        var prefix = 0
        while prefix < oldUnits.count, prefix < newUnits.count, oldUnits[prefix] == newUnits[prefix] { prefix += 1 }

        var suffix = 0
        while suffix < oldUnits.count - prefix, suffix < newUnits.count - prefix,
              oldUnits[oldUnits.count - suffix - 1] == newUnits[newUnits.count - suffix - 1] {
            suffix += 1
        }

        let oldEnd = oldUnits.count - suffix
        let newEnd = newUnits.count - suffix
        let replacement = String(decoding: newUnits[prefix..<newEnd], as: UTF16.self)
        var requests = [GoogleDocsRequest]()
        if oldEnd > prefix {
            requests.append(serializeDeletion(startIndex: prefix + 1, endIndex: oldEnd + 1))
        }
        if !replacement.isEmpty {
            requests.append(serializeInsertion(text: replacement, at: prefix + 1))
        }
        return requests
    }
}

public extension GoogleDocsRequest {
    func withTabID(_ tabID: String) -> GoogleDocsRequest {
        let insertion = insertText.map {
            InsertTextRequest(text: $0.text, location: Location(index: $0.location.index, tabId: tabID))
        }
        let deletion = deleteContentRange.map {
            DeleteContentRangeRequest(range: RangeElement(startIndex: $0.range.startIndex, endIndex: $0.range.endIndex, tabId: tabID))
        }
        return GoogleDocsRequest(insertText: insertion, deleteContentRange: deletion)
    }
}
