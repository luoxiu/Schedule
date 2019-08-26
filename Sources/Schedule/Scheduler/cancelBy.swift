#if canImport(ObjectiveC)
import Foundation

extension Cancellable where Self: AnyObject {
    
    public func cancel(by obj: AnyObject) {
        Lifetime.of(obj).onEnd(self.cancel)
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
    private var hasEnded = false
    private var callbacks: [() -> Void] = []
    
    private func end() {
        self.lock.lock()
        self.hasEnded = true
        let callbacks = self.callbacks
        self.callbacks = []
        self.lock.unlock()
        
        callbacks.forEach {
            $0()
        }
    }
    
    
    func onEnd(_ callback: @escaping () -> Void) {
        self.lock.lock()
        if self.hasEnded {
            self.lock.unlock()
            callback()
            return
        }
        self.callbacks.append(callback)
        self.lock.unlock()
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

