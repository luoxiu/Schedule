final public class AnyCancellable: Cancellable {
    
    private var body: (() -> Void)?
    
    public init(_ cancel: @escaping () -> Void) {
        self.body = cancel
    }
    
    public init<C>(_ canceller: C) where C: Cancellable {
        self.body = canceller.cancel
    }
    
    final public func cancel() {
        self.body?()
        self.body = nil
    }
    
    deinit {
        self.body?()
    }
}
