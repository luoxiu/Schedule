import XCTest
@testable import Schedule

final class ScheduleTests: XCTestCase {
    
    func testMakeSchedule() {
        let intervals = [1.second, 2.hours, 3.days, 4.weeks]
        let s0 = Schedule.of(intervals[0], intervals[1], intervals[2], intervals[3])
        XCTAssert(s0.makeIterator().isEqual(to: intervals, leeway: 0.001.seconds))
        let s1 = Schedule.from(intervals)
        XCTAssert(s1.makeIterator().isEqual(to: intervals, leeway: 0.001.seconds))

        
        let d0 = Date() + intervals[0]
        let d1 = d0 + intervals[1]
        let d2 = d1 + intervals[2]
        let d3 = d2 + intervals[3]
        
        let s2 = Schedule.of(d0, d1, d2, d3)
        let s3 = Schedule.from([d0, d1, d2, d3])
        XCTAssert(s2.makeIterator().isEqual(to: intervals, leeway: 0.001.seconds))
        XCTAssert(s3.makeIterator().isEqual(to: intervals, leeway: 0.001.seconds))
    }
    
    func testDates() {
        let iterator = Schedule.of(1.days, 2.weeks).dates.makeIterator()
        var next = iterator.next()
        XCTAssertNotNil(next)
        XCTAssert(next!.intervalSinceNow.isEqual(to: 1.days, leeway: 0.001.seconds))
        next = iterator.next()
        XCTAssertNotNil(next)
        XCTAssert(next!.intervalSinceNow.isEqual(to: 2.weeks + 1.days, leeway: 0.001.seconds))
    }
    
    func testNever() {
        XCTAssertNil(Schedule.never.makeIterator().next())
    }
    
    func testConcat() {
        let s0: [Interval] = [1.second, 2.minutes, 3.hours]
        let s1: [Interval] = [4.days, 5.weeks]
        let s3 = Schedule.from(s0).concat(Schedule.from(s1))
        let s4 = Schedule.from(s0 + s1)
        XCTAssert(s3.makeIterator().isEqual(to: s4.makeIterator(), leeway: 0.001.seconds))
    }
    
    func testAt() {
        let s = Schedule.at(Date() + 1.second)
        let next = s.makeIterator().next()
        XCTAssertNotNil(next)
        XCTAssert(next!.isEqual(to: 1.second, leeway: 0.001.seconds))
    }
    
    func testCount() {
        var count = 10
        let s = Schedule.every(1.second).count(count)
        let i = s.makeIterator()
        while count > 0 {
            XCTAssertNotNil(i.next())
            count -= 1
        }
        XCTAssertNil(i.next())
    }
    
    func testUntil() {
        let until = Date() + 10.seconds
        let s = Schedule.every(1.second).until(until).dates
        let i = s.makeIterator()
        while let date = i.next() {
            XCTAssertLessThan(date, until)
        }
    }
    
    func testMerge() {
        let intervals0: [Interval] = [1.second, 2.minutes, 1.hour]
        let intervals1: [Interval] = [2.seconds, 1.minutes, 1.seconds]
        
        let scheudle0 = Schedule.from(intervals0).merge(Schedule.from(intervals1))
        
        let scheudle1 = Schedule.of(1.second, 1.second, 1.minutes, 1.seconds, 58.seconds, 1.hour)
        XCTAssert(scheudle0.makeIterator().isEqual(to: scheudle1.makeIterator(), leeway: 0.001.seconds))
    }
    
    func testEveryPeriod() {
        let s = Schedule.every(1.year).count(10)
        
        var date = Date()
        for i in s.dates {
            XCTAssertEqual(i.dateComponents.year!, date.dateComponents.year! + 1)
            XCTAssertEqual(i.dateComponents.month!, date.dateComponents.month!)
            XCTAssertEqual(i.dateComponents.day!, date.dateComponents.day!)
            date = i
        }
    }
    
    func testEveryWeekday() {
        let s = Schedule.every(.friday).at("11:11:00").count(5)
        
        for i in s.dates {
            XCTAssertEqual(i.dateComponents.weekday, 6)
            XCTAssertEqual(i.dateComponents.hour, 11)
        }
    }
    
    func testEveryMonthday() {
        let s = Schedule.every(.april(2)).at(11, 11).count(5)
        for i in s.dates {
            print(i.localizedDescription)
            print(i.dateComponents)
            XCTAssertEqual(i.dateComponents.month, 4)
            XCTAssertEqual(i.dateComponents.day, 2)
            XCTAssertEqual(i.dateComponents.hour, 11)
        }
    }

    static var allTests = [
        ("testExample", testMakeSchedule),
    ]
}
