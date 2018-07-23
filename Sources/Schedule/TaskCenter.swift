//
//  TaskCenter.swift
//  Schedule
//
//  Created by Quentin Jin on 2018/7/17.
//

import Foundation

final class TaskCenter {
    
    static let shared = TaskCenter()
    
    private init() { }
    
    private var lock = NSLock()
    
    private var tasks: Set<Task> = []
    private var tags: [String: NSHashTable<Task>] = [:]
    
    func add(_ task: Task, withTag tag: String? = nil) {
        lock.lock()
        defer { lock.unlock() }
        
        tasks.insert(task)
        
        if let tag = tag {
            if tags[tag] == nil {
                tags[tag] = NSHashTable<Task>(options: .weakMemory)
            }
            weak var t = task
            tags[tag]?.add(t)
        }
    }
    
    func remove(_ task: Task) {
        lock.lock()
        defer { lock.unlock() }
        
        tasks.remove(task)
    }
    
    func add(tag: String, to task: Task) {
        lock.lock()
        defer { lock.unlock() }
        
        if tags[tag] == nil {
            tags[tag] = NSHashTable<Task>(options: .weakMemory)
        }
        weak var t = task
        tags[tag]?.add(t)
    }
    
    func remove(tag: String, from task: Task) {
        lock.lock()
        defer { lock.unlock() }
        
        tags[tag]?.remove(task)
    }
    
    func tasks(forTag tag: String) -> [Task] {
        lock.lock()
        defer { lock.unlock() }
        
        return tags[tag]?.allObjects ?? []
    }
}

