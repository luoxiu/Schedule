import Foundation

#if canImport(ObjectiveC)

private var DEINIT_OBSERVER_KEY: Void = ()

/// Used to observe object deinit.
///
///     let observer = DeinitObserver.observe(target) {
///         print("\(target) deinit")
///     }
///
///     observer.cancel()
class DeinitObserver {

    private(set) weak var observed: AnyObject?

    private var action: (() -> Void)?

    private init(_ action: @escaping () -> Void) {
        self.action = action
    }

    /// Add observer.
    @discardableResult
    static func observe(
        _ object: AnyObject,
        onDeinit action: @escaping () -> Void
    ) -> DeinitObserver {
        let observer = DeinitObserver(action)
        observer.observed = object

        objc_setAssociatedObject(object, &DEINIT_OBSERVER_KEY, observer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        return observer
    }

    /// Remove observer.
    func cancel() {
        action = nil
        if let o = observed {
            objc_setAssociatedObject(o, &DEINIT_OBSERVER_KEY, nil, .OBJC_ASSOCIATION_ASSIGN)
        }
    }

    deinit {
        action?()
    }
}

#endif
