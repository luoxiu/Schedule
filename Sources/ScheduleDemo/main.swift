//
//  main.swift
//  Schedule
//
//  Created by Quentin Jin on 2019/3/12.
//  Copyright © 2019 Schedule. All rights reserved.
//

import Foundation
import Schedule

Log("Wake up")

let t1 = Plan.after(1.second).do {
    Log("1 second passed!")
}

let t2 = Plan.after(1.minute, repeating: 0.5.seconds).do {
    Log("Ping!")
}

let t3 = Plan.every("one minute and ten seconds").do {
    Log("One minute and ten seconds have elapsed!")
}

let t4 = Plan.every(.monday, .tuesday, .wednesday, .thursday, .friday).at(6, 50).do {
    Log("Get up!")
}

let t5 = Plan.every(.march(14)).at("08:59:59 am").do {
    Log("Happy birthday!")
}

RunLoop.current.run()
