import XCTest

#if os(Linux)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(DateTimeTests.allTests),
        testCase(PlanTests.allTests),
        testCase(TaskCenterTests.allTests),
        testCase(TaskTests.allTests),
        testCase(AtomicTests.allTests),
        testCase(CabinetTests.allTests),
        testCase(CalendarTests.allTests),
        testCase(ExtensionsTests.allTests)
    ]
}
#endif
