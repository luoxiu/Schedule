import XCTest

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(DateTimeTests.allTests),
        testCase(SchedulesTests.allTests),
        testCase(TaskHubTests.allTests),
        testCase(TaskTests.allTests),
        testCase(AtomicTests.allTests),
        testCase(BucketTests.allTests),
        testCase(ExtensionsTests.allTests)
    ]
}
#endif
