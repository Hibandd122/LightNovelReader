import SwiftUI

/// Wrapper to pass NSUndoManager from UIKit/AppKit to SwiftUI views safely
public struct UndoManagerWrapper {
    public let undoManager: UndoManager
    
    public init(undoManager: UndoManager = UndoManager()) {
        self.undoManager = undoManager
    }
    
    public func undo() {
        if undoManager.canUndo {
            undoManager.undo()
        }
    }
    
    public func redo() {
        if undoManager.canRedo {
            undoManager.redo()
        }
    }
    
    public var canUndo: Bool {
        undoManager.canUndo
    }
    
    public var canRedo: Bool {
        undoManager.canRedo
    }
}
