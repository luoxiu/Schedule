//
//  Extensions.swift
//  Schedule
//
//  Created by Quentin Jin on 2018/7/22.
//

import Foundation

extension FixedWidthInteger {
    
    func clampedAdding(_ other: Self) -> Self {
        let r = addingReportingOverflow(other)
        return r.overflow ? (other > 0 ? .max : .min) : r.partialValue
    }
    
    func clampedSubtracting(_ other: Self) -> Self {
        let r = subtractingReportingOverflow(other)
        return r.overflow ? (other > 0 ? .max : .min) : r.partialValue
    }
}

extension String {
    
    func matches(pattern: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return []
        }
        let matches = regex.matches(in: self, options: [], range: NSRange(location: 0, length: count))
        guard let match = matches.first else { return [] }
        
        var results: [String] = []
        for i in 0..<match.numberOfRanges {
            results.append((self as NSString).substring(with: match.range(at: i)))
        }
        return results
    }
}
