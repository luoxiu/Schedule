import XCTest
@testable import Schedule

#if canImport(ObjectiveC)

final class DeinitObserverTests: XCTestCase {

    func testObserver() {
        var i = 0
        let b0 = {
            let obj = NSObject()
            DeinitObserver.observe(obj, onDeinit: {
                i += 1
            })
        }
        b0()
        XCTAssertEqual(i, 1)

        let b1 = {
            let obj = NSObject()
            let observer = DeinitObserver.observe(obj, onDeinit: {
                i += 1
            })
            observer.cancel()
        }
        b1()
        XCTAssertEqual(i, 1)
    }

    static var allTests = [
        ("testObserver", testObserver)
    ]
}

#endif
