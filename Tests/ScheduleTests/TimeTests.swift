import XCTest
@testable import Schedule

final class TimeTests: XCTestCase {
    
    func testTime() {
        let t1 = Time("11:12:13.456")
        XCTAssertNotNil(t1)
        XCTAssertEqual(t1?.hour, 11)
        XCTAssertEqual(t1?.minute, 12)
        XCTAssertEqual(t1?.second, 13)
        if let i = t1?.nanosecond.nanoseconds {
            XCTAssertTrue(i.isAlmostEqual(to: 0.456.second, leeway: 0.001.seconds))
        }

        let t2 = Time("11 pm")
        XCTAssertNotNil(t2)
        XCTAssertEqual(t2?.hour, 23)

        let t3 = Time("12 am")
        XCTAssertNotNil(t3)
        XCTAssertEqual(t3?.hour, 0)

        let t4 = Time("schedule")
        XCTAssertNil(t4)
    }
    
    func testIntervalSinceStartOfDay() {
        XCTAssertEqual(Time(hour: 1)!.intervalSinceStartOfDay, 1.hour)
    }
    
    func testAsDateComponents() {
        let time = Time(hour: 11, minute: 12, second: 13, nanosecond: 456)
        let components = time?.asDateComponents()
        XCTAssertEqual(components?.hour, 11)
        XCTAssertEqual(components?.minute, 12)
        XCTAssertEqual(components?.second, 13)
        XCTAssertEqual(components?.nanosecond, 456)
    }
    
    func testDescription() {
        let time = Time("11:12:13.456")
        XCTAssertEqual(time!.debugDescription, "Time: 11:12:13.456")
    }

    static var allTests = [
        ("testTime", testTime),
        ("testIntervalSinceStartOfDay", testIntervalSinceStartOfDay),
        ("testAsDateComponents", testAsDateComponents),
        ("testDescription", testDescription)
    ]
}
