import XCTest
@testable import Schedule

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)

final class DeinitObserverTests: XCTestCase {

    func testObserver() {
        var i = 0
        var fn = {
            let obj = NSObject()
            DeinitObserver.observe(obj) {
                i += 1
            }
        }
        fn()
        XCTAssertEqual(i, 1)

        fn = {
            let obj = NSObject()
            let observer = DeinitObserver.observe(obj) {
                i += 1
            }
            observer.cancel()
        }
        fn()
        XCTAssertEqual(i, 1)
    }

    static var allTests = [
        ("testObserver", testObserver)
    ]
}

#endif
