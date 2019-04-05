import Foundation

#if canImport(ObjectiveC)

/// An observer that receives deinit event of the object.
///
///     let observer = DeinitObserver.observe(target) {
///         print("\(target) deinit")
///     }
///
///     observer.cancel()
class DeinitObserver {

    private var associateKey: Void = ()

    private(set) weak var observed: AnyObject?

    private var block: (() -> Void)?

    private init(_ block: @escaping () -> Void) {
        self.block = block
    }

    /// Observe deinit event of the object.
    @discardableResult
    static func observe(
        _ object: AnyObject,
        using block: @escaping () -> Void
    ) -> DeinitObserver {
        let observer = DeinitObserver(block)
        observer.observed = object

        objc_setAssociatedObject(object, &observer.associateKey, observer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        return observer
    }

    /// Cancel observing.
    func cancel() {
        block = nil
        if let o = observed {
            objc_setAssociatedObject(o, &associateKey, nil, .OBJC_ASSOCIATION_ASSIGN)
        }
    }

    deinit {
        block?()
    }
}

#endif
