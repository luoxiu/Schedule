//: Playground - noun: a place where people can play

import PlaygroundSupport
import Foundation
import Schedule

PlaygroundPage.current.needsIndefiniteExecution = true

Schedule.after(1.second).do {
    print("1 seconds passed!")
}

Schedule.every(.june(14)).at("9:30").do {
    print("Happy birthday!")
}

