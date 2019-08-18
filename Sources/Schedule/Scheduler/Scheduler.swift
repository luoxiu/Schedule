import Foundation

public protocol Scheduler {
    
    associatedtype ScheduleOptions
    
    func schedule(after seconds: Double, options: ScheduleOptions?, _ action: @escaping () -> Void) -> Cancellable
}

