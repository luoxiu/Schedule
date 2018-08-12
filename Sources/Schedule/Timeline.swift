//
//  Timeline.swift
//  Schedule
//
//  Created by Quentin Jin on 2018/7/25.
//

import Foundation

/// `Timeline` records a task's schedule.
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
