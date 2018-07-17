//
//  JobCenter.swift
//  Schedule
//
//  Created by Quentin Jin on 2018/7/17.
//

import Foundation

final class JobCenter {
    
    static let shared = JobCenter()
    
    private var lock = NSLock()
    
    private var jobs: [Int: Job] = [:]
    private var tags: [String: Set<Job?>] = [:]
    
    func add(_ job: Job, tag: String? = nil) {
        lock.lock()
        defer { lock.unlock() }
        
        jobs[job.hashValue] = job
        if let tag = tag {
            if tags[tag] == nil { tags[tag] = [] }
            weak var j = job
            tags[tag]?.insert(j)
        }
    }
    
    func remove(_ job: Job) {
        lock.lock()
        defer { lock.unlock() }
        
        jobs[job.hashValue] = nil
    }
    
    func jobs(for tag: String) -> [Job] {
        lock.lock()
        defer { lock.unlock() }
        
        if let jobs = tags[tag] {
            return jobs.compactMap({ $0 })
        }
        return []
    }
}

