import XCTest
@testable import Schedule

#if canImport(ObjectiveC)

final class DeinitObserverTests: XCTestCase {

    func testObserve() {
        var i = 0
        let fn = {
            let obj = NSObject()
            DeinitObserver.observe(obj) {
                i += 1
            }
        }
        fn()
        XCTAssertEqual(i, 1)
    }
    
    func testCancel() {
        var i = 0
        let fn = {
            let obj = NSObject()
            let observer = DeinitObserver.observe(obj) {
                i += 1
            }
            observer.cancel()
        }
        fn()
        XCTAssertEqual(i, 0)
    }

    static var allTests = [
        ("testObserve", testObserve),
        ("testCancel", testCancel)
    ]
}

#endif
