//
//  Log.swift
//  Schedule
//
//  Created by Quentin Jin on 2019/3/12.
//  Copyright © 2019 Schedule. All rights reserved.
//

import Foundation

let fmt = ISO8601DateFormatter()

func Log(_ t: Any) {

    let now = fmt.string(from: Date())
    let thread = Thread.isMainThread ? "main" : "background"
    
    print("\(now) [\(thread)] -> \(t)")
}
