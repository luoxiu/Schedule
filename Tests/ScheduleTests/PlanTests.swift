import XCTest
@testable import Schedule

final class PlanTests: XCTestCase {

    let leeway = 0.01.seconds

    func testMake() {
        let intervals = [1.second, 2.hours, 3.days, 4.weeks]
        let s0 = Plan.of(intervals[0], intervals[1], intervals[2], intervals[3])
        XCTAssertTrue(s0.makeIterator().isAlmostEqual(to: intervals, leeway: leeway))
        let s1 = Plan.from(intervals)
        XCTAssertTrue(s1.makeIterator().isAlmostEqual(to: intervals, leeway: leeway))

        let d0 = Date() + intervals[0]
        let d1 = d0 + intervals[1]
        let d2 = d1 + intervals[2]
        let d3 = d2 + intervals[3]

        let s2 = Plan.of(d0, d1, d2, d3)
        let s3 = Plan.from([d0, d1, d2, d3])
        XCTAssertTrue(s2.makeIterator().isAlmostEqual(to: intervals, leeway: leeway))
        XCTAssertTrue(s3.makeIterator().isAlmostEqual(to: intervals, leeway: leeway))

        let longTime = (100 * 365).days
        XCTAssertTrue(Plan.distantPast.makeIterator().next()!.isLonger(than: longTime))
        XCTAssertTrue(Plan.distantFuture.makeIterator().next()!.isLonger(than: longTime))
    }

    func testDates() {
        let iterator = Plan.of(1.days, 2.weeks).dates.makeIterator()
        var next = iterator.next()
        XCTAssertNotNil(next)
        XCTAssertTrue(next!.intervalSinceNow.isAlmostEqual(to: 1.days, leeway: leeway))
        next = iterator.next()
        XCTAssertNotNil(next)
        XCTAssertTrue(next!.intervalSinceNow.isAlmostEqual(to: 2.weeks + 1.days, leeway: leeway))
    }

    func testNever() {
        XCTAssertNil(Plan.never.makeIterator().next())
    }

    func testConcat() {
        let s0: [Interval] = [1.second, 2.minutes, 3.hours]
        let s1: [Interval] = [4.days, 5.weeks]
        let s3 = Plan.from(s0).concat(Plan.from(s1))
        let s4 = Plan.from(s0 + s1)
        XCTAssertTrue(s3.isAlmostEqual(to: s4, leeway: leeway))
    }

    func testMerge() {
        let intervals0: [Interval] = [1.second, 2.minutes, 1.hour]
        let intervals1: [Interval] = [2.seconds, 1.minutes, 1.seconds]
        let scheudle0 = Plan.from(intervals0).merge(Plan.from(intervals1))
        let scheudle1 = Plan.of(1.second, 1.second, 1.minutes, 1.seconds, 58.seconds, 1.hour)
        XCTAssertTrue(scheudle0.isAlmostEqual(to: scheudle1, leeway: leeway))
    }

    func testAt() {
        let s = Plan.at(Date() + 1.second)
        let next = s.makeIterator().next()
        XCTAssertNotNil(next)
        XCTAssertTrue(next!.isAlmostEqual(to: 1.second, leeway: leeway))
    }

    func testFirst() {
        var count = 10
        let s = Plan.every(1.second).first(count)
        let i = s.makeIterator()
        while count > 0 {
            XCTAssertNotNil(i.next())
            count -= 1
        }
        XCTAssertNil(i.next())
    }

    func testUntil() {
        let until = Date() + 10.seconds
        let s = Plan.every(1.second).until(until).dates
        let i = s.makeIterator()
        while let date = i.next() {
            XCTAssertLessThan(date, until)
        }
    }

    func testNow() {
        let s0 = Plan.now
        let s1 = Plan.of(Date())
        XCTAssertTrue(s0.isAlmostEqual(to: s1, leeway: leeway))
    }

    func testAfterAndRepeating() {
        let s0 = Plan.after(1.day, repeating: 1.hour).first(3)
        let s1 = Plan.of(1.day, 1.hour, 1.hour)
        XCTAssertTrue(s0.isAlmostEqual(to: s1, leeway: leeway))
    }

    func testEveryPeriod() {
        let s = Plan.every("1 year").first(10)
        var date = Date()
        for i in s.dates {
            XCTAssertEqual(i.dateComponents.year!, date.dateComponents.year! + 1)
            XCTAssertEqual(i.dateComponents.month!, date.dateComponents.month!)
            XCTAssertEqual(i.dateComponents.day!, date.dateComponents.day!)
            date = i
        }
    }

    func testEveryWeekday() {
        let s = Plan.every(.friday, .monday).at("11:11:00").first(5)
        for i in s.dates {
            XCTAssertTrue(i.dateComponents.weekday == 6 || i.dateComponents.weekday == 2)
            XCTAssertEqual(i.dateComponents.hour, 11)
        }
    }

    func testEveryMonthday() {
        let s = Plan.every(.april(1), .october(1)).at(11, 11).first(5)
        for i in s.dates {
            XCTAssertTrue(i.dateComponents.month == 4 || i.dateComponents.month == 10)
            XCTAssertEqual(i.dateComponents.day, 1)
            XCTAssertEqual(i.dateComponents.hour, 11)
        }
    }

    static var allTests = [
        ("testMake", testMake),
        ("testDates", testDates),
        ("testNever", testNever),
        ("testConcat", testConcat),
        ("testMerge", testMerge),
        ("testAt", testAt),
        ("testFirst", testFirst),
        ("testUntil", testUntil),
        ("testNow", testNow),
        ("testAfterAndRepeating", testAfterAndRepeating),
        ("testEveryPeriod", testEveryPeriod),
        ("testEveryWeekday", testEveryWeekday),
        ("testEveryMonthday", testEveryMonthday)
    ]
}
