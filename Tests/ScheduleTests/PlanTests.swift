import XCTest
@testable import Schedule

final class PlanTests: XCTestCase {

    private let leeway = 0.01.seconds

    func testOfIntervals() {
        let ints = [1.second, 2.hours, 3.days, 4.weeks]
        let p = Plan.of(ints)
        XCTAssertTrue(p.makeIterator().isAlmostEqual(to: ints, leeway: leeway))
    }

    func testOfDates() {
        let ints = [1.second, 2.hours, 3.days, 4.weeks]

        let d0 = Date() + ints[0]
        let d1 = d0 + ints[1]
        let d2 = d1 + ints[2]
        let d3 = d2 + ints[3]

        let p = Plan.of(d0, d1, d2, d3)
        XCTAssertTrue(p.makeIterator().isAlmostEqual(to: ints, leeway: leeway))
    }

    func testDates() {
        let dates = Plan.of(1.days, 2.weeks).dates.makeIterator()

        var n = dates.next()
        XCTAssertNotNil(n)
        XCTAssertTrue(n!.intervalSinceNow.isAlmostEqual(to: 1.days, leeway: leeway))

        n = dates.next()
        XCTAssertNotNil(n)
        XCTAssertTrue(n!.intervalSinceNow.isAlmostEqual(to: 2.weeks + 1.days, leeway: leeway))
    }

    func testDistant() {
        let distantPast = Plan.distantPast.makeIterator().next()
        XCTAssertNotNil(distantPast)
        XCTAssertTrue(distantPast!.isAlmostEqual(to: Date.distantPast.intervalSinceNow, leeway: leeway))

        let distantFuture = Plan.distantFuture.makeIterator().next()
        XCTAssertNotNil(distantFuture)
        XCTAssertTrue(distantFuture!.isAlmostEqual(to: Date.distantFuture.intervalSinceNow, leeway: leeway))
    }

    func testNever() {
        XCTAssertNil(Plan.never.makeIterator().next())
    }

    func testConcat() {
        let p0: [Interval] = [1.second, 2.minutes, 3.hours]
        let p1: [Interval] = [4.days, 5.weeks]
        let p2 = Plan.of(p0).concat(Plan.of(p1))
        let p3 = Plan.of(p0 + p1)
        XCTAssertTrue(p2.isAlmostEqual(to: p3, leeway: leeway))
    }

    func testMerge() {
        let ints0: [Interval] = [1.second, 2.minutes, 1.hour]
        let ints1: [Interval] = [2.seconds, 1.minutes, 1.seconds]
        let p0 = Plan.of(ints0).merge(Plan.of(ints1))
        let p1 = Plan.of(1.second, 1.second, 1.minutes, 1.seconds, 58.seconds, 1.hour)
        XCTAssertTrue(p0.isAlmostEqual(to: p1, leeway: leeway))
    }

    func testFirst() {
        var count = 10
        let p = Plan.every(1.second).first(count)
        let i = p.makeIterator()
        while count > 0 {
            XCTAssertNotNil(i.next())
            count -= 1
        }
        XCTAssertNil(i.next())
    }

    func testUntil() {
        let until = Date() + 10.seconds
        let p = Plan.every(1.second).until(until).dates
        let i = p.makeIterator()
        while let date = i.next() {
            XCTAssertLessThan(date, until)
        }
    }

    func testNow() {
        let p0 = Plan.now
        let p1 = Plan.of(Date())
        XCTAssertTrue(p0.isAlmostEqual(to: p1, leeway: leeway))
    }

    func testAt() {
        let p = Plan.at(Date() + 1.second)
        let next = p.makeIterator().next()
        XCTAssertNotNil(next)
        XCTAssertTrue(next!.isAlmostEqual(to: 1.second, leeway: leeway))
    }

    func testAfterAndRepeating() {
        let p0 = Plan.after(1.day, repeating: 1.hour).first(3)
        let p1 = Plan.of(1.day, 1.hour, 1.hour)
        XCTAssertTrue(p0.isAlmostEqual(to: p1, leeway: leeway))
    }

    func testEveryPeriod() {
        let p = Plan.every("1 year").first(10)
        var date = Date()
        for i in p.dates {
            XCTAssertEqual(i.dateComponents.year!, date.dateComponents.year! + 1)
            XCTAssertEqual(i.dateComponents.month!, date.dateComponents.month!)
            XCTAssertEqual(i.dateComponents.day!, date.dateComponents.day!)
            date = i
        }
    }

    func testEveryWeekday() {
        let p = Plan.every(.friday, .monday).at("11:11:00").first(5)
        for i in p.dates {
            XCTAssertTrue(i.dateComponents.weekday == 6 || i.dateComponents.weekday == 2)
            XCTAssertEqual(i.dateComponents.hour, 11)
        }
    }

    func testEveryMonthday() {
        let p = Plan.every(.april(1), .october(1)).at(11, 11).first(5)
        for i in p.dates {
            XCTAssertTrue(i.dateComponents.month == 4 || i.dateComponents.month == 10)
            XCTAssertEqual(i.dateComponents.day, 1)
            XCTAssertEqual(i.dateComponents.hour, 11)
        }
    }

    func testOffset() {
        let p1 = Plan.after(1.second).first(100)
        let p2 = p1.offset(by: 1.second).first(100)

        for (d1, d2) in zip(p1.dates, p2.dates) {
            XCTAssertTrue(d2.interval(since: d1).isAlmostEqual(to: 1.second, leeway: leeway))
        }
    }

    static var allTests = [
        ("testOfIntervals", testOfIntervals),
        ("testOfDates", testOfDates),
        ("testDates", testDates),
        ("testDistant", testDistant),
        ("testNever", testNever),
        ("testConcat", testConcat),
        ("testMerge", testMerge),
        ("testFirst", testFirst),
        ("testUntil", testUntil),
        ("testNow", testNow),
        ("testAt", testAt),
        ("testAfterAndRepeating", testAfterAndRepeating),
        ("testEveryPeriod", testEveryPeriod),
        ("testEveryWeekday", testEveryWeekday),
        ("testEveryMonthday", testEveryMonthday),
        ("testOffset", testOffset)
    ]
}
