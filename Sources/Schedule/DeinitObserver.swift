import Foundation

#if canImport(ObjectiveC)

private var deinitObserverKey: Void = ()

class DeinitObserver {

    private(set) weak var object: AnyObject?

    private var action: (() -> Void)?

    private init(_ action: @escaping () -> Void) {
        self.action = action
    }

    @discardableResult
    static func observe(
        _ object: AnyObject,
        onDeinit action: @escaping () -> Void
    ) -> DeinitObserver {
        let observer = DeinitObserver(action)
        observer.object = object

        objc_setAssociatedObject(object, &deinitObserverKey, observer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        return observer
    }

    func invalidate() {
        action = nil
        if let o = object {
            objc_setAssociatedObject(o, &deinitObserverKey, nil, .OBJC_ASSOCIATION_ASSIGN)
        }
    }

    deinit {
        action?()
    }
}

#endif
