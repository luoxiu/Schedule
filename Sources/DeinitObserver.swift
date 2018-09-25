import Foundation

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)

private var deinitObserverKey: Void = ()

class DeinitObserver {

    private(set) weak var observable: AnyObject?

    private var block: (() -> Void)?

    private init(_ block: @escaping () -> Void) {
        self.block = block
    }

    @discardableResult
    static func observe(_ observable: AnyObject, whenDeinit block: @escaping () -> Void) -> DeinitObserver {
        let observer = DeinitObserver(block)
        objc_setAssociatedObject(observable, &deinitObserverKey, observer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return observer
    }

    func clear() {
        block = nil
        if let o = observable {
            objc_setAssociatedObject(o, &deinitObserverKey, nil, .OBJC_ASSOCIATION_ASSIGN)
        }
    }

    deinit {
        block?()
    }
}

#endif
