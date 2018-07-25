//
//  Timeline.swift
//  Schedule
//
//  Created by Quentin Jin on 2018/7/25.
//

import Foundation

/// `Timeline` records a task's schedule.
public struct Timeline {
    
    /// The time when the first time task was scheduled.
    public internal(set) var firstSchedule: Date?
    
    /// The time when the last time task was scheduled.
    public internal(set) var lastSchedule: Date?
    
    /// The time when the next time task will be scheduled.
    public internal(set) var nextSchedule: Date?
    
    /// The time when task was activated.
    public internal(set) var activate: Date?
    
    /// The time when task was canceled.
    public internal(set) var cancel: Date?
    
    init() { }
}
