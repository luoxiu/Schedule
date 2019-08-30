import Foundation

public protocol SuspendableScheduler: Scheduler {
    
    func suspend()
    
    func resume()
}
