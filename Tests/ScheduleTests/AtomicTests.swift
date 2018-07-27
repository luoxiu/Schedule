//
//  AtomicTests.swift
//  ScheduleTests
//
//  Created by Quentin Jin on 2018/7/27.
//

import XCTest
@testable import Schedule

final class AtomicTests: XCTestCase {

    func testExecute() {
        let atom = Atomic<Int>(1)
        atom.execute {
            XCTAssertEqual($0, 1)
        }
    }

    func testMutate() {
        let atom = Atomic<Int>(1)
        atom.mutate {
            $0 = 2
        }
        XCTAssertEqual(atom.read(), 2)
    }

    func testReadWrite() {
        let atom = Atomic<Int>(1)
        atom.write(3)
        XCTAssertEqual(atom.read(), 3)
    }

    static var allTests = [
        ("testExecute", testExecute),
        ("testMutate", testMutate)
    ]
}
