import UIKit

public enum ReadingMode {
    case continuousScroll
    case paginated
}

/// Handles switching between Scroll Mode and Page Mode.
public final class PaginationEngine {
    private weak var containerView: UIView?
    private let textView: UITextView
    private var pageViewController: UIPageViewController?
    
    public var currentMode: ReadingMode = .continuousScroll
    
    public init(containerView: UIView, textView: UITextView) {
        self.containerView = containerView
        self.textView = textView
    }
    
    public func switchTo(mode: ReadingMode) {
        self.currentMode = mode
        
        switch mode {
        case .continuousScroll:
            enableScrollMode()
        case .paginated:
            enablePageMode()
        }
    }
    
    private func enableScrollMode() {
        // Tear down UIPageViewController if it exists
        pageViewController?.view.removeFromSuperview()
        pageViewController?.removeFromParent()
        pageViewController = nil
        
        textView.isScrollEnabled = true
        textView.isPagingEnabled = false
        containerView?.addSubview(textView)
        textView.frame = containerView?.bounds ?? .zero
        textView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    private func enablePageMode() {
        // Keep the same TextKit-backed view and let UIKit snap by viewport.
        // The previous implementation removed the text view and created an
        // empty UIPageViewController, which made page mode appear blank.
        pageViewController?.view.removeFromSuperview()
        pageViewController?.removeFromParent()
        pageViewController = nil

        guard let container = containerView else { return }
        textView.isScrollEnabled = true
        textView.isPagingEnabled = true
        container.addSubview(textView)
        textView.frame = container.bounds
        textView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
}