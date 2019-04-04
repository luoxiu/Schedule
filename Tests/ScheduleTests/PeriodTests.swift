import XCTest
@testable import Schedule

final class PeriodTests: XCTestCase {
    
    func testPeriod() {
        let period = (1.year + 2.years + 1.month + 2.months + 3.days)
        XCTAssertEqual(period.years, 3)
        XCTAssertEqual(period.months, 3)
        XCTAssertEqual(period.days, 3)
    }
    
    func testInitWithString() {
        let p1 = Period("one second")
        XCTAssertNotNil(p1)
        XCTAssertEqual(p1!.seconds, 1)
        
        let p2 = Period("two hours and ten minutes")
        XCTAssertNotNil(p2)
        XCTAssertEqual(p2!.hours, 2)
        XCTAssertEqual(p2!.minutes, 10)
        
        let p3 = Period("1 year, 2 months and 3 days")
        XCTAssertNotNil(p3)
        XCTAssertEqual(p3!.years, 1)
        XCTAssertEqual(p3!.months, 2)
        XCTAssertEqual(p3!.days, 3)
        
        Period.registerQuantifier("many", for: 100 * 1000)
        let p4 = Period("many days")
        XCTAssertEqual(p4!.days, 100 * 1000)
    }
    
    func testAdd() {
        XCTAssertEqual(1.month.adding(1.month).months, 2)
        XCTAssertEqual(Period(days: 1).adding(1.day).days, 2)
    }
    
    func testTidy() {
        let period = 1.month.adding(25.hour).tidied(to: .day)
        XCTAssertEqual(period.days, 1)
    }
    
    func testAsDateComponents() {
        let period = Period(years: 1, months: 2, days: 3, hours: 4, minutes: 5, seconds: 6, nanoseconds: 7)
        let comps = period.asDateComponents()
        XCTAssertEqual(comps.year, 1)
        XCTAssertEqual(comps.month, 2)
        XCTAssertEqual(comps.day, 3)
        XCTAssertEqual(comps.hour, 4)
        XCTAssertEqual(comps.minute, 5)
        XCTAssertEqual(comps.second, 6)
        XCTAssertEqual(comps.nanosecond, 7)
    }
    
    func testDate() {
        let d = Date(year: 1989, month: 6, day: 4) + 1.year
        let year = d.dateComponents.year
        XCTAssertEqual(year, 1990)
    }
    
    func testDescription() {
        let period = Period(years: 1, nanoseconds: 1)
        XCTAssertEqual(period.debugDescription, "Period: 1 year(s) 1 nanosecond(s)")
    }

    static var allTests = [
        ("testPeriod", testPeriod),
        ("testInitWithString", testInitWithString),
        ("testAdd", testAdd),
        ("testTidy", testTidy),
        ("testAsDateComponents", testAsDateComponents),
        ("testDate", testDate),
        ("testDescription", testDescription)
    ]
}
