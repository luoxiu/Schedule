import Foundation

extension RunLoop: Scheduler {
    
    public func schedule(after seconds: Double, _ action: @escaping () -> Void) -> Cancellable {
        let timer = Timer(timeInterval: seconds, repeats: false) { (_) in
            action()
        }
        self.add(timer, forMode: .default)
        return AnyCancellable(timer.invalidate)
    }
}
