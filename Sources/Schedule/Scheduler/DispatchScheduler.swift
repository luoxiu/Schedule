import Foundation

extension DispatchQueue: Scheduler {
    
    public typealias ScheduleOptions = DispatchQoS
    
    public func schedule(after seconds: Double, options: ScheduleOptions?, _ action: @escaping () -> Void) -> Cancellable {
        let timer = DispatchSource.makeTimerSource(queue: self)
        
        timer.setEventHandler(qos: options ?? .unspecified, handler: action)
        timer.schedule(deadline: .now() + seconds)
        timer.resume()
        
        return AnyCancellable(timer.cancel)
    }
}
