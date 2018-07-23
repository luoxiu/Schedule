//
//  JobCenter.swift
//  Schedule
//
//  Created by Quentin Jin on 2018/7/17.
//

import Foundation

final class JobCenter {
    
    static let shared = JobCenter()
    
    private init() { }
    
    private var lock = NSLock()
    
    private var jobs: Set<Job> = []
    private var tags: [String: NSHashTable<Job>] = [:]
    
    func add(_ job: Job, withTag tag: String? = nil) {
        lock.lock()
        defer { lock.unlock() }
        
        jobs.insert(job)
        
        if let tag = tag {
            if tags[tag] == nil {
                tags[tag] = NSHashTable<Job>(options: .weakMemory)
            }
            weak var j = job
            tags[tag]?.add(j)
        }
    }
    
    func remove(_ job: Job) {
        lock.lock()
        defer { lock.unlock() }
        
        jobs.remove(job)
    }
    
    func add(tag: String, for job: Job) {
        lock.lock()
        defer { lock.unlock() }
        
        if tags[tag] == nil {
            tags[tag] = NSHashTable<Job>(options: .weakMemory)
        }
        weak var j = job
        tags[tag]?.add(j)
    }
    
    func remove(tag: String, from job: Job) {
        lock.lock()
        defer { lock.unlock() }
        
        tags[tag]?.remove(job)
    }
    
    func jobs(forTag tag: String) -> [Job] {
        lock.lock()
        defer { lock.unlock() }
        
        return tags[tag]?.allObjects ?? []
    }
}

