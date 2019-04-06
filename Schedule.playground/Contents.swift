import PlaygroundSupport
import Schedule

PlaygroundPage.current.needsIndefiniteExecution = true

let t1 = Plan.after(1.second).do {
    print("1 second passed!")
}

let t2 = Plan.after(1.minute, repeating: 0.5.seconds).do {
    print("Ping!")
}

let t3 = Plan.every("one minute and ten seconds").do {
    print("One minute and ten seconds have elapsed!")
}

let t4 = Plan.every(.monday, .tuesday, .wednesday, .thursday, .friday).at(6, 30).do {
    print("Get up!")
}

let t5 = Plan.every(.june(14)).at("9:30").do {
    print("Happy birthday!")
}
