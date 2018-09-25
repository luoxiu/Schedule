import Foundation

extension Calendar {

    func next(_ weekday: Weekday, after date: Date = Date()) -> Date? {
        let components = weekday.toDateComponents()

        #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)

        return nextDate(after: date, matching: components, matchingPolicy: .strict)

        #elseif os(Linux)

        var c = dateComponents(in: .current, from: date)
        var days = components.weekday! - c.weekday!
        if days <= 0 {
            days += 7
        }
        return self.date(byAdding: .day, value: days, to: date)?.zeroToday()

        #endif
    }

    func next(_ monthday: Monthday, after date: Date = Date()) -> Date? {
        let components = monthday.toDateComponents()

        #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)

        return nextDate(after: date, matching: components, matchingPolicy: .strict)

        #elseif os(Linux)

        var old = dateComponents(in: .current, from: date)
        var new = DateComponents(calendar: self, timeZone: .current)
        new.year = old.year
        new.month = components.month
        new.day = components.day
        if components.month! < old.month! {
            new.year! += 1
        } else if components.month! == old.month! {
            if components.day! <= old.day! {
                new.year! += 1
            }
        }
        return self.date(from: new)

        #endif
    }
}
