import Foundation

/// `Timeline` records a task's lifecycle.
public struct Timeline {

    /// The time of initialization.
    public let initialization = Date()

    /// The time of first execution.
    public internal(set) var firstExecution: Date?

    /// The time of last execution.
    public internal(set) var lastExecution: Date?

    /// The time of estimated next execution.
    public internal(set) var estimatedNextExecution: Date?

    init() { }
}

extension Timeline: CustomStringConvertible {

    /// A textual representation of this timeline.
    public var description: String {

        let desc = { (d: Date?) -> String in
            guard let d = d else { return "nil" }
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
            return f.string(from: d)
        }

        return "Timeline: { " +
            "\"initialization\": \(desc(initialization))" +
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
