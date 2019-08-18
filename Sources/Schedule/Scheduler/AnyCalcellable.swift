/// A type-erasing cancellable object that executes a provided closure when canceled.
final public class AnyCancellable: Cancellable {
    
    private var cancelBody: (() -> Void)?
    
    /// Initializes the cancellable object with the given cancel-time closure.
    ///
    /// - Parameter cancel: A closure that the `cancel()` method executes.
    public init(_ cancel: @escaping () -> Void) {
        self.cancelBody = cancel
    }
    
    public init<C>(_ canceller: C) where C: Cancellable {
        self.cancelBody = canceller.cancel
    }
    
    /// Cancel the activity.
    final public func cancel() {
        self.cancelBody?()
        self.cancelBody = nil
    }
    
    deinit {
        self.cancelBody?()
    }
}
