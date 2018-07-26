import XCTest

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(DateTimeTests.allTests),
        testCase(SchedulesTests.allTests),
        testCase(TaskCenterTests.allTests),
        testCase(ExtensionsTests.allTests),
        testCase(BucketTests.allTests),
        testCase(WeakSetTests.allTests)
    ]
}
#endif
