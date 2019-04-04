import XCTest
@testable import Schedule

final class MonthdayTests: XCTestCase {
    
    func testIs() {
        // ! Be careful the time zone problem.
        let d = Date(year: 2019, month: 1, day: 1)
        XCTAssertTrue(d.is(.january(1)))
    }
    
    func testAsDateComponents() {
        let comps = Monthday.april(1).asDateComponents()
        XCTAssertEqual(comps.month, 4)
        XCTAssertEqual(comps.day, 1)
    }
    
    func testDescription() {
        let md = Monthday.april(1)
        XCTAssertEqual(md.debugDescription, "Monthday: April 1st")
    }
    
    static var allTests = [
        ("testIs", testIs),
        ("testAsDateComponents", testAsDateComponents),
        ("testDescription", testDescription)
    ]
}
