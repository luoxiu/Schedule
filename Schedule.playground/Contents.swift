//: Playground - noun: a place where people can play

import PlaygroundSupport
import Schedule

PlaygroundPage.current.needsIndefiniteExecution = true

Plan.after(1.second).do {
    print("1 second passed!")
}

Plan.after(1.minute, repeating: 0.5.seconds).do {
    print("Ping!")
}

Plan.every("one minute and ten seconds").do {
    print("One minute and ten seconds have elapsed!")
}

Plan.every(.monday, .tuesday, .wednesday, .thursday, .friday).at(6, 30).do {
    print("Get up!")
}

Plan.every(.june(14)).at("9:30").do {
    print("Happy birthday!")
}

