//
//  Timeline.swift
//  Schedule
//
//  Created by Quentin Jin on 2018/7/25.
//

import Foundation

/// `Timeline` records a task's lifecycle.
public struct Timeline {

    /// The time of first execution.
    public internal(set) var firstExecution: Date?

    /// The time of last execution.
    public internal(set) var lastExecution: Date?

    /// The time of next execution.
    public internal(set) var estimatedNextExecution: Date?

    let initialize = Date()

    init() { }
}

extension Timeline: CustomStringConvertible {

    /// A textual representation of this timeline.
    public var description: String {

        let desc = { (d: Date?) -> String in
            guard let d = d else { return "nil" }
            return String(format: "%.3f", d.timeIntervalSinceReferenceDate)
        }

        return "Timeline: { " +
        "\"firstExecution\": \(desc(firstExecution)), " +
        "\"lastExecution\": \(desc(lastExecution)), " +
        "\"estimatedNextExecution\": \(desc(estimatedNextExecution))" +
        " }"
    }
}

extension Timeline: CustomDebugStringConvertible {

    /// A textual representation of this timeline for debugging.
    public var debugDescription: String {
        return description
    }
}
