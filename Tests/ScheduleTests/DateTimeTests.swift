//
//  DateTimeTests.swift
//  Schedule
//
//  Created by Quentin Jin on 2018/7/2.
//

import XCTest
@testable import Schedule

final class DateTimeTests: XCTestCase {
    
    func testInterval2DispatchInterval() {
        let i0 = 1.23.seconds
        XCTAssertEqual(i0.dispatchInterval, DispatchTimeInterval.nanoseconds(Int(i0.nanoseconds)))
        
        let i1 = 4.56.minutes + 7.89.hours
        XCTAssertEqual(i1.dispatchInterval, DispatchTimeInterval.nanoseconds(Int(i1.nanoseconds)))
    }
    
    func testIntervalConvertible() {
        XCTAssertEqual(1.nanoseconds, Interval(nanoseconds: 1))
        XCTAssertEqual(2.microseconds, Interval(nanoseconds: 2 * K.ns_per_us))
        XCTAssertEqual(3.milliseconds, Interval(nanoseconds: 3 * K.ns_per_ms))
        XCTAssertEqual(4.seconds, Interval(nanoseconds: 4 * K.ns_per_s))
        XCTAssertEqual(5.1.minutes, Interval(nanoseconds: 5.1 * K.ns_per_m))
        XCTAssertEqual(6.2.hours, Interval(nanoseconds: 6.2 * K.ns_per_h))
        XCTAssertEqual(7.3.days, Interval(nanoseconds: 7.3 * K.ns_per_d))
        XCTAssertEqual(8.4.weeks, Interval(nanoseconds: 8.4 * K.ns_per_w))
    }
    
    func testTimeConstructor() {
        let t0 = Time(hour: -1, minute: -2, second: -3, nanosecond: -4)
        XCTAssertNil(t0)
        
        let t1 = Time(timing: "11:12:13.456")
        XCTAssertNotNil(t1)
        XCTAssertEqual(t1?.hour, 11)
        XCTAssertEqual(t1?.minute, 12)
        XCTAssertEqual(t1?.second, 13)
        XCTAssertEqual(t1?.nanosecond, Int(0.456 * K.ns_per_s))
    }
    
    func testPeriodAnd() {
        let dateComponents = 1.year + 2.months + 3.days
        XCTAssertEqual(dateComponents.years, 1)
        XCTAssertEqual(dateComponents.months, 2)
        XCTAssertEqual(dateComponents.days, 3)
    }
    
    func testMonthDay() {
        XCTAssertEqual(MonthDay.april(3).asDateComponents(), DateComponents(month: 4, day: 3))
    }
    
    static var allTests = [
        ("testInterval2DispatchInterval", testInterval2DispatchInterval),
        ("testInterval", testIntervalConvertible),
        ("testTimeConstructor", testTimeConstructor),
        ("testPeriodAnd", testPeriodAnd),
        ("testMonthDay", testMonthDay)
    ]
}

