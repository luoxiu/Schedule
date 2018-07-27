//
//  Timeline.swift
//  Schedule
//
//  Created by Quentin Jin on 2018/7/25.
//

import Foundation

/// `Timeline` records a task's schedule.
public struct Timeline {

    /// The time when the first time task was executed.
    public internal(set) var firstExecution: Date?

    /// The time when the last time task was executed.
    public internal(set) var lastExecution: Date?

    /// The time when the next time task will be executed.
    public internal(set) var estimatedNextExecution: Date?

    let initialize = Date()

    init() { }
}
