import XCTest
@testable import Schedule

final class CalendarTests: XCTestCase {

    func testNextWeekday() {

        let date = Date(year: 2018, month: 8, day: 1, hour: 6)

        let n0 = Calendar.gregorian.next(.monday, after: date)
        XCTAssertEqual(n0?.dateComponents.year, 2018)
        XCTAssertEqual(n0?.dateComponents.month, 8)
        XCTAssertEqual(n0?.dateComponents.day, 6)
        XCTAssertEqual(n0?.dateComponents.weekday, 2)

        let n1 = Calendar.gregorian.next(.friday, after: date)
        XCTAssertEqual(n1?.dateComponents.year, 2018)
        XCTAssertEqual(n1?.dateComponents.month, 8)
        XCTAssertEqual(n1?.dateComponents.day, 3)
        XCTAssertEqual(n1?.dateComponents.weekday, 6)
    }

    func testNextMonthday() {

        let date = Date(year: 2000, month: 4, day: 1, hour: 6)

        let n0 = Calendar.gregorian.next(.april(1), after: date)
        XCTAssertEqual(n0?.dateComponents.year, 2001)
        XCTAssertEqual(n0?.dateComponents.month, 4)
        XCTAssertEqual(n0?.dateComponents.day, 1)

        let n1 = Calendar.gregorian.next(.october(10), after: date)
        XCTAssertEqual(n1?.dateComponents.year, 2000)
        XCTAssertEqual(n1?.dateComponents.month, 10)
        XCTAssertEqual(n1?.dateComponents.day, 10)
    }

    static var allTests = [
        ("testNextWeekday", testNextWeekday),
        ("testNextMonthday", testNextMonthday)
    ]
}
