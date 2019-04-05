import XCTest
@testable import Schedule

final class WeekdayTests: XCTestCase {

    func testIs() {
        // ! Be careful the time zone problem.
        let d = Date(year: 2019, month: 1, day: 1)
        XCTAssertTrue(d.is(.tuesday, in: TimeZone.shanghai))
    }

    func testAsDateComponents() {
        XCTAssertEqual(Weekday.monday.asDateComponents().weekday!, 2)
    }

    func testDescription() {
        let wd = Weekday.tuesday
        XCTAssertEqual(wd.debugDescription, "Weekday: Tuesday")
    }

    static var allTests = [
        ("testIs", testIs),
        ("testAsDateComponents", testAsDateComponents),
        ("testDescription", testDescription)
    ]
}
