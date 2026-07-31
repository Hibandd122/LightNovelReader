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
        // Hide standard text view
        textView.removeFromSuperview()
        
        // Setup UIPageViewController
        pageViewController = UIPageViewController(transitionStyle: .pageCurl, navigationOrientation: .horizontal, options: nil)
        
        if let pageVC = pageViewController, let container = containerView {
            container.addSubview(pageVC.view)
            pageVC.view.frame = container.bounds
            pageVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            
            // In a real app, feed view controllers with chunked attributed text here
        }
    }
}
