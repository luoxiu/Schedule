import Foundation

extension DispatchQueue: Scheduler {

    public func schedule(after seconds: Double, _ action: @escaping () -> Void) -> Cancellable {
        let timer = DispatchSource.makeTimerSource(queue: self)
        
        timer.setEventHandler(handler: action)
        timer.schedule(deadline: .now() + seconds)
        timer.resume()
        
        return AnyCancellable(timer.cancel)
    }
}
