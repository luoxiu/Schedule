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

    private var lock = Lock()

    private var tasks: Set<Task> = []
    private var registry: [String: WeakSet<Task>] = [:]

    func add(_ task: Task, withTag tag: String? = nil) {
        lock.withLock {
            tasks.insert(task)
            if let tag = tag {
                if registry[tag] == nil {
                    registry[tag] = WeakSet()
                }
                registry[tag]?.add(task)
            }
        }
    }

    func remove(_ task: Task) {
        lock.withLock {
            _ = tasks.remove(task)
        }
    }

    func add(tag: String, to task: Task) {
        lock.withLock {
            if registry[tag] == nil {
                registry[tag] = WeakSet()
            }
            registry[tag]?.add(task)
        }
    }

    func remove(tag: String, from task: Task) {
        lock.withLock {
            _ = registry[tag]?.remove(task)
        }
    }

    func tasks(forTag tag: String) -> [Task] {
        return lock.withLock {
            registry[tag]?.objects ?? []
        }
    }

    func contains(_ task: Task) -> Bool {
        return lock.withLock {
            tasks.contains(task)
        }
    }

    var countOfTask: Int {
        return lock.withLock {
            tasks.count
        }
    }
}
