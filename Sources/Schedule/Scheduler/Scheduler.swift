import Foundation

public protocol Scheduler {
    
    func schedule(after seconds: Double, _ action: @escaping () -> Void) -> Cancellable
}
