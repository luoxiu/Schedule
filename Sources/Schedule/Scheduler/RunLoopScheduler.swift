import Foundation

extension RunLoop: Scheduler {
    
    public typealias ScheduleOptions = Mode
    
    public func schedule(after seconds: Double, options: ScheduleOptions?, _ action: @escaping () -> Void) -> Cancellable {
        let timer = Timer(timeInterval: seconds, repeats: false) { (_) in
            action()
        }
        self.add(timer, forMode: options ?? .default)
        
        return AnyCancellable(timer.invalidate)
    }
}
