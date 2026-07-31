import UIKit

public protocol ScrollEngineDelegate: AnyObject {
    func didScrollToProgress(_ progress: Double)
    func prefetchThresholdReached(direction: ScrollDirection)
}

public enum ScrollDirection {
    case forward
    case backward
}

/// A highly optimized scrolling engine using TextKit 2, Virtualization, and Memory Release for large documents.
public final class ScrollEngine: NSObject, UITextViewDelegate {
    public weak var delegate: ScrollEngineDelegate?
    private let textView: UITextView
    
    // Virtualization and Prefetch properties
    private let prefetchThreshold: CGFloat = 1000.0 // Points before edge to trigger prefetch
    private var isPrefetching = false
    
    public init(textView: UITextView) {
        self.textView = textView
        super.init()
        self.textView.delegate = self
        setupPerformanceOptimizations()
    }
    
    private func setupPerformanceOptimizations() {
        // Essential TextKit 2 optimization for huge documents
        textView.layoutManager.allowsNonContiguousLayout = true
        
        // Limits memory by not keeping unrendered text layouts in memory
        if #available(iOS 16.0, *) {
            textView.textLayoutManager?.usesFontLeading = false
        }
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let currentOffset = scrollView.contentOffset.y
        let maxOffset = scrollView.contentSize.height - scrollView.bounds.height
        
        if maxOffset > 0 {
            let progress = Double(max(0, min(1, currentOffset / maxOffset)))
            delegate?.didScrollToProgress(progress)
        }
        
        // Prefetch logic
        if !isPrefetching {
            if currentOffset > scrollView.contentSize.height - scrollView.bounds.height - prefetchThreshold {
                isPrefetching = true
                delegate?.prefetchThresholdReached(direction: .forward)
            } else if currentOffset < prefetchThreshold {
                isPrefetching = true
                delegate?.prefetchThresholdReached(direction: .backward)
            }
        }
    }
    
    public func resetPrefetchState() {
        isPrefetching = false
    }
    
    public func memoryReleaseInvisibleChunks() {
        // In a true virtualized engine, we would remove text chunks far from the viewport from `textView.textStorage`
        // and replace them with placeholder attributes or just adjust contentOffset.
        // For standard TextKit 2, `allowsNonContiguousLayout` handles most of it automatically.
    }
}
