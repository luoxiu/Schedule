//
//  IntervalTests.swift
//  ScheduleTests
//
//  Created by Quentin MED on 2019/4/4.
//

import XCTest
@testable import Schedule

final class IntervalTests: XCTestCase {

    private let leeway = 0.01.second

    func testEquatable() {
        XCTAssertEqual(1.second, 1.second)
        XCTAssertEqual(1.week, 7.days)
    }

    func testIsNegative() {
        XCTAssertFalse(1.second.isNegative)
        XCTAssertTrue((-1).second.isNegative)
    }

    func testAbs() {
        XCTAssertEqual(1.second, (-1).second.abs)
    }

    func testNegated() {
        XCTAssertEqual(1.second.negated, (-1).second)
        XCTAssertEqual(1.second.negated.negated, 1.second)
    }

    func testCompare() {
        XCTAssertEqual((-1).second.compare(1.second), ComparisonResult.orderedAscending)
        XCTAssertEqual(8.days.compare(1.week), ComparisonResult.orderedDescending)
        XCTAssertEqual(1.day.compare(24.hours), ComparisonResult.orderedSame)

        XCTAssertTrue(23.hours < 1.day)
        XCTAssertTrue(25.hours > 1.day)
    }

    func testLongerShorter() {
        XCTAssertTrue((-25).hour.isLonger(than: 1.day))
        XCTAssertTrue(1.week.isShorter(than: 8.days))
    }

    func testMultiplying() {
        XCTAssertEqual(7.days * 2, 2.week)
    }

    func testAdding() {
        XCTAssertEqual(6.days + 1.day, 1.week)

        XCTAssertEqual(1.1.weeks, 1.week + 0.1.weeks)
    }

    func testOperators() {
        XCTAssertEqual(1.week - 6.days, 1.day)

        var i = 6.days
        i += 1.day
        XCTAssertEqual(i, 1.week)

        XCTAssertEqual(-(7.days), (-1).week)
    }

    func testAs() {
        XCTAssertEqual(1.millisecond.asNanoseconds(), 1.microsecond.asNanoseconds() * pow(10, 3))

        XCTAssertEqual(1.second.asNanoseconds(), pow(10, 9))
        XCTAssertEqual(1.second.asMicroseconds(), pow(10, 6))
        XCTAssertEqual(1.second.asMilliseconds(), pow(10, 3))

        XCTAssertEqual(1.minute.asSeconds(), 60)
        XCTAssertEqual(1.hour.asMinutes(), 60)
        XCTAssertEqual(1.day.asHours(), 24)
        XCTAssertEqual(1.week.asDays(), 7)
        XCTAssertEqual(7.days.asWeeks(), 1)
    }

    func testDate() {
        let date0 = Date()
        let date1 = date0.addingTimeInterval(100)

        XCTAssertTrue(date1.intervalSinceNow.isAlmostEqual(to: 100.seconds, leeway: leeway))

        XCTAssertEqual(date0.interval(since: date1), date0.timeIntervalSince(date1).seconds)

        XCTAssertEqual(date0.adding(1.seconds), date0.addingTimeInterval(1))
        XCTAssertEqual(date0 + 1.seconds, date0.addingTimeInterval(1))
    }

    func testDescription() {
        XCTAssertEqual(1.nanosecond.debugDescription, "Interval: 1 nanosecond(s)")
    }

    static var allTests = [
        ("testEquatable", testEquatable),
        ("testIsNegative", testIsNegative),
        ("testAbs", testAbs),
        ("testNegated", testNegated),
        ("testCompare", testCompare),
        ("testLongerShorter", testLongerShorter),
        ("testMultiplying", testMultiplying),
        ("testAdding", testAdding),
        ("testOperators", testOperators),
        ("testAs", testAs),
        ("testDate", testDate)
    ]
}
