/// A protocol indicating that an activity or action may be canceled.
public protocol Cancellable {
    
    /// Cancel the activity.
    func cancel()
}
