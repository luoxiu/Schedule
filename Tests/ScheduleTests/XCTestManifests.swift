import XCTest

#if os(Linux)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(AtomicTests.allTests),
        testCase(BagTests.allTests),
        testCase(ExtensionsTests.allTests),
        testCase(IntervalTests.allTests),
        testCase(MonthdayTests.allTests),
        testCase(PeriodTests.allTests),
        testCase(PlanTests.allTests),
        testCase(TaskCenterTests.allTests),
        testCase(TaskTests.allTests),
        testCase(TimeTests.allTests),
        testCase(WeekdayTests.allTests)
    ]
}
#endif
