import XCTest
@testable import Schedule

final class DateTimeTests: XCTestCase {

    func testInterval() {

        XCTAssertTrue((-1).second.isNegative)
        XCTAssertTrue(1.second.isPositive)
        XCTAssertEqual(1.1.second.magnitude, 1.1.second.nanoseconds)
        XCTAssertEqual(1.second.opposite, (-1).second)

        XCTAssertEqual(7.day.hashValue, 1.week.hashValue)
        XCTAssertEqual(7.day, 1.week)

        XCTAssertEqual((-2).seconds.compare(1.second), .orderedAscending)
        XCTAssertTrue(1.1.second > 1.0.second)
        XCTAssertTrue(3.days < 1.week)
        XCTAssertTrue(4.day >= 4.days)
        XCTAssertTrue(-2.seconds < 1.seconds)

        XCTAssertTrue(1.1.second.isLonger(than: 1.0.second))
        XCTAssertTrue(3.days.isShorter(than: 1.week))
        XCTAssertEqual(Interval.longest(1.hour, 1.day, 1.week), 1.week)
        XCTAssertEqual(Interval.shortest(1.hour, 59.minutes, 2999.seconds), 2999.seconds)

        XCTAssertEqual(1.second * 60, 1.minute)
        XCTAssertEqual(59.minutes + 60.seconds, 1.hour)
        XCTAssertEqual(1.week - 24.hours, 6.days)
        var i0 = 1.day
        i0 += 1.day
        XCTAssertEqual(i0, 2.days)
        XCTAssertEqual(-(1.second), (-1).second)

        let i1 = Interval(seconds: 24 * 60 * 60)
        XCTAssertEqual(1.nanosecond * i1.nanoseconds, 1.day)
        XCTAssertEqual(2.microsecond * i1.asMicroseconds(), 2.days)
        XCTAssertEqual(3.millisecond * i1.asMilliseconds(), 3.days)
        XCTAssertEqual(4.second * i1.asSeconds(), 4.days)
        XCTAssertEqual(5.1.minute * i1.asMinutes(), 5.1.days)
        XCTAssertEqual(6.2.hour * i1.asHours(), 6.2.days)
        XCTAssertEqual(7.3.day * i1.asDays(), 7.3.days)
        XCTAssertEqual(1.week * i1.asWeeks(), 1.days)

        let date0 = Date()
        let date1 = date0.addingTimeInterval(100)
        XCTAssertEqual(date0.interval(since: date1), date0.timeIntervalSince(date1).seconds)
        XCTAssertEqual(date0.adding(1.seconds), date0.addingTimeInterval(1))
        XCTAssertEqual(date0 + 1.seconds, date0.addingTimeInterval(1))
    }

    func testMonthday() {
        XCTAssertEqual(Monthday.january(1).toDateComponents().month, 1)
        XCTAssertEqual(Monthday.february(1).toDateComponents().month, 2)
        XCTAssertEqual(Monthday.march(1).toDateComponents().month, 3)
        XCTAssertEqual(Monthday.april(1).toDateComponents().month, 4)
        XCTAssertEqual(Monthday.may(1).toDateComponents().month, 5)
        XCTAssertEqual(Monthday.june(1).toDateComponents().month, 6)
        XCTAssertEqual(Monthday.july(1).toDateComponents().month, 7)
        XCTAssertEqual(Monthday.august(1).toDateComponents().month, 8)
        XCTAssertEqual(Monthday.september(1).toDateComponents().month, 9)
        XCTAssertEqual(Monthday.october(1).toDateComponents().month, 10)
        XCTAssertEqual(Monthday.november(1).toDateComponents().month, 11)
        XCTAssertEqual(Monthday.december(1).toDateComponents().month, 12)
    }

    func testPeriod() {
        let p0 = (1.year + 2.years + 1.month + 2.months + 3.days).tidied(to: .day)
        XCTAssertEqual(p0.years, 3)
        XCTAssertEqual(p0.months, 3)
        XCTAssertEqual(p0.days, 3)

        let p1 = Period("one second")?.tidied(to: .second)
        XCTAssertNotNil(p1)
        XCTAssertEqual(p1!.seconds, 1)
        let p2 = Period("two hours and ten minutes")?.tidied(to: .day)
        XCTAssertNotNil(p2)
        XCTAssertEqual(p2!.hours, 2)
        XCTAssertEqual(p2!.minutes, 10)
        let p3 = Period("1 year, 2 months and 3 days")?.tidied(to: .day)
        XCTAssertNotNil(p3)
        XCTAssertEqual(p3!.years, 1)
        XCTAssertEqual(p3!.months, 2)
        XCTAssertEqual(p3!.days, 3)

        Period.registerQuantifier("many", for: 100 * 1000)
        let p4 = Period("many days")
        XCTAssertEqual(p4!.days, 100 * 1000)

        let date = Date(year: 1989, month: 6, day: 4) + 1.year
        let year = date.dateComponents.year
        XCTAssertEqual(year, 1990)

        let p5 = Period(hours: 25).tidied(to: .day)
        XCTAssertEqual(p5.days, 1)
    }

    func testTime() {
        let t0 = Time(hour: -1, minute: -2, second: -3, nanosecond: -4)
        XCTAssertNil(t0)

        let t1 = Time("11:12:13.456")
        XCTAssertNotNil(t1)
        XCTAssertEqual(t1?.hour, 11)
        XCTAssertEqual(t1?.minute, 12)
        XCTAssertEqual(t1?.second, 13)
        if let i = t1?.nanosecond.nanoseconds {
            XCTAssertTrue(i.isAlmostEqual(to: (0.456.second.nanoseconds).nanoseconds, leeway: 0.001.seconds))
        }

        let t2 = Time("11 pm")
        XCTAssertNotNil(t2)
        XCTAssertEqual(t2?.hour, 23)

        let t3 = Time("12 am")
        XCTAssertNotNil(t3)
        XCTAssertEqual(t3?.hour, 0)

        let t4 = Time("schedule")
        XCTAssertNil(t4)

        XCTAssertEqual(Time(hour: 1)!.intervalSinceZeroClock, 1.hour)
    }

    func testWeekday() {
        XCTAssertEqual(Weekday.monday.toDateComponents().weekday!, 2)
    }

    static var allTests = [
        ("testInterval", testInterval),
        ("testMonthday", testMonthday),
        ("testPeriod", testPeriod),
        ("testTime", testTime),
        ("testWeekday", testWeekday)
    ]
}
