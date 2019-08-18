#if canImport(ObjectiveC)
import Foundation

extension Cancellable where Self: AnyObject {
    
    public func cancel(by obj: AnyObject) {
        Lifetime.of(obj).whenEnd(self.cancel)
    }
}

private class Lifetime {
    
    private class Tracer {
        let lifetime = Lifetime()
        init() { }
        
        deinit {
            self.lifetime.end()
        }
    }
    
    private let lock = NSLock()
    private var _hasEnded = false
    private var _callbacks: [() -> Void] = []
    
    var hasEnded: Bool {
        return self.lock.withLock {
            self._hasEnded
        }
    }
    
    private func end() {
        self.lock.lock()
        
        self._hasEnded = true
        let callbacks = self._callbacks
        self._callbacks = []
        
        self.lock.unlock()
        
        callbacks.forEach {
            $0()
        }
    }
    
    
    func whenEnd(_ callback: @escaping () -> Void) {
        self.lock.withLockVoid {
            self._callbacks.append(callback)
        }
    }
    
    static func of(_ obj: AnyObject) -> Lifetime {
        enum Once {
            static var tracer: Void = ()
        }
        return Global.sync(obj) {
            if let tracer = objc_getAssociatedObject(obj, &Once.tracer) as? Tracer {
                return tracer.lifetime
            }
            let tracer = Tracer()
            objc_setAssociatedObject(obj, &Once.tracer, tracer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return tracer.lifetime
        }
    }
}

#endif

