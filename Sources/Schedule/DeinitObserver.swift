import Foundation

#if canImport(ObjectiveC)

private var deinitObserverKey: Void = ()

class DeinitObserver {

    private(set) weak var observed: AnyObject?

    private var block: (() -> Void)?

    private init(_ block: @escaping () -> Void) {
        self.block = block
    }

    @discardableResult
    static func observe(_ observed: AnyObject, onDeinit block: @escaping () -> Void) -> DeinitObserver {
        let observer = DeinitObserver(block)
        observer.observed = observed

        objc_setAssociatedObject(observed, &deinitObserverKey, observer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        return observer
    }

    func cancel() {
        block = nil

        if let o = observed {
            objc_setAssociatedObject(o, &deinitObserverKey, nil, .OBJC_ASSOCIATION_ASSIGN)
        }
    }

    deinit {
        block?()
    }
}

#endif
