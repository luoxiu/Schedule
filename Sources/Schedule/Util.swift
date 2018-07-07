//
//  Util.swift
//  Schedule
//
//  Created by Quentin MED on 2018/7/3.
//

import Foundation

class AtomicBox<Wrapped> {
    
    private var lock = NSLock()
    
    private var value: Wrapped
    
    init(_ value: Wrapped) {
        self.value = value
    }
    
    func withLock<T>(_ block: (inout Wrapped) throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try block(&value)
    }
}

extension String {
    
    func matches(pattern: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return []
        }
        let matches = regex.matches(in: self, options: [], range: NSRange(location: 0, length: count))
        guard let match = matches.first else { return [] }
        
        var result: [String] = []
        for i in 0..<match.numberOfRanges {
            result.append((self as NSString).substring(with: match.range(at: i)))
        }
        return result
    }
}

extension Int {
    
    func clampedAdding(_ other: Int) -> Int {
        let r = addingReportingOverflow(other)
        return r.overflow ? (other > 0 ? .max : .min) : r.partialValue
    }
    
    func clampedSubtracting(_ other: Int) -> Int {
        let r = subtractingReportingOverflow(other)
        return r.overflow ? (other > 0 ? .max : .min) : r.partialValue
    }
}
