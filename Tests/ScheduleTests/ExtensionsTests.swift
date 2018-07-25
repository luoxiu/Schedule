//
//  ExtensionsTests.swift
//  Schedule
//
//  Created by Quentin Jin on 2018/7/24.
//

import XCTest
@testable import Schedule

final class ExtensionsTests: XCTestCase {
    
    func testClampedAdding() {
        let a: Int = 1
        let b: Int = .max
        XCTAssertEqual(a.clampedAdding(b), Int.max)
    }
    
    func testClampedSubtracting() {
        let a: Int = .min
        let b: Int = 1
        XCTAssertEqual(a.clampedSubtracting(b), Int.min)
    }
    
    static var allTests = [
        ("testClampedAdding", testClampedAdding),
        ("testClampedSubtracting", testClampedSubtracting)
    ]
}
