import Foundation
@testable import Schedule

extension Date {

    var dateComponents: DateComponents {
        return Calendar.gregorian.dateComponents(in: TimeZone.current, from: self)
    }

    init(
        year: Int, month: Int, day: Int,
        hour: Int = 0, minute: Int = 0, second: Int = 0,
        nanosecond: Int = 0
        ) {
        let components = DateComponents(
            calendar: Calendar.gregorian,
            timeZone: TimeZone.current,
            year: year, month: month, day: day,
            hour: hour, minute: minute, second: second,
            nanosecond: nanosecond
        )
        self = components.date ?? Date.distantPast
    }
}

extension Interval {

    func isAlmostEqual(to interval: Interval, leeway: Interval) -> Bool {
        return (interval - self).abs <= leeway.abs
    }
}

extension Double {

    func isAlmostEqual(to double: Double, leeway: Double) -> Bool {
        return (double - self).magnitude <= leeway
    }
}

extension Sequence where Element == Interval {

    func isAlmostEqual<S>(to sequence: S, leeway: Interval) -> Bool where S: Sequence, S.Element == Element {
        var it0 = self.makeIterator()
        var it1 = sequence.makeIterator()

        while let l = it0.next(), let r = it1.next() {
            if l.isAlmostEqual(to: r, leeway: leeway) {
                continue
            } else {
                return false
            }
        }
        return it0.next() == it1.next()
    }
}

extension Plan {

    func isAlmostEqual(to plan: Plan, leeway: Interval) -> Bool {
        return makeIterator().isAlmostEqual(to: plan.makeIterator(), leeway: leeway)
    }
}

extension DispatchQueue {

    func async(after interval: Interval, execute body: @escaping () -> Void) {
        asyncAfter(wallDeadline: .now() + interval.asSeconds(), execute: body)
    }

    static func `is`(_ queue: DispatchQueue) -> Bool {
        let key = DispatchSpecificKey<()>()

        queue.setSpecific(key: key, value: ())
        defer { queue.setSpecific(key: key, value: nil) }

        return DispatchQueue.getSpecific(key: key) != nil
    }
}

extension TimeZone {
    
    static let shanghai = TimeZone(identifier: "Asia/Shanghai")!
}
