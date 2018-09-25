import XCTest
@testable import Schedule

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)

final class DeinitObserverTests: XCTestCase {

    func testObserver() {
        var de = false
        let block = {
            let obj = NSObject()
            DeinitObserver.observe(obj, whenDeinit: {
                de = true
            })
        }
        block()
        XCTAssertTrue(de)
    }

    static var allTests = [
        ("testObserver", testObserver)
    ]
}

#endif
