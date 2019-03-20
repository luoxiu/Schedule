# Schedule([简体中文](README.zh_cn.md))

<p align="center">

[![Build Status](https://travis-ci.org/jianstm/Schedule.svg?branch=master)](https://travis-ci.org/jianstm/Schedule)
[![codecov](https://codecov.io/gh/jianstm/Schedule/branch/master/graph/badge.svg)](https://codecov.io/gh/jianstm/Schedule)
<a href="https://github.com/jianstm/Schedule/releases">
  <img src="https://img.shields.io/github/tag/jianstm/Schedule.svg">
</a>
<img src="https://img.shields.io/badge/support-CocoaPods%20%7C%20Carthage%20%7C%20SwiftPM-brightgreen.svg">
<img src="https://img.shields.io/badge/platform-iOS%20%7C%20macOS%20%7C%20watchOS%20%7C%20tvOS%20%7C%20Linux-lightgrey.svg">
</p>

Schedule is a lightweight timed tasks scheduler for Swift. It allows you run timed tasks using an incredibly human-friendly syntax.

<p align="center">
<img src="assets/demo.png" width="700">
</p>

## Features

- [x] Variety of Scheduling Rules 
- [x] Suspend, Resume, Cancel
- [x] Reschedule
- [x] Tag-based Task Management
- [x] Child-action Add/Remove
- [x] Natural Language Parse
- [x] Atomic Operation
- [x] Full Control Over Life Cycle 
- [x] 95%+ Test Coverage
- [x] Complete Documentation(All Public Types & Methods)
- [x] Linux Support(Tested on Ubuntu 16.04)

### Why You Should Use Schedule

| Features | Timer | DispatchSourceTimer | Schedule |
| --- | :---: | :---: | :---: |
| ⏰ Interval-based Schedule | ✓ | ✓ | ✓ |
| 📆 Date-based Schedule | ✓ | | ✓ |
| 🌈 Mixing Rules Schedule | | | ✓ |
| 🚦 Suspend, Resume, Cancel | | ✓ | ✓ |
| 🎡 Reschedule | | ✓ | ✓ |
| 🏷 Tag-based Task Management | | | ✓ |
| 🍰 Child-action Add/Remove | | | ✓ |
| 📝 Natural Language Parse | | | ✓ |
| 🚔 Atomic Operation | | | ✓ |
| 🕕 Lifecycly Bind | | | ✓ |
| 🚀 Realtime Timeline Inspect | | | ✓ |
| 🎯 Lifetime Specify | | | ✓ |

## Usage

### Overview

Scheduling a task has never been so simple and intuitive, all you have to do is:

```swift
// 1. define your plan：
let plan = Plan.after(3.seconds)

// 2. do your task：
let task = plan.do {
    print("3 seconds passed!")
}
```

### Rules

#### Interval-based Schedule

Schedule uses a self-defined type `Interval` to configure timed tasks, so you don't have to worry about extensions of built-in type polluting your namespace. The smooth constructors make the configuration like a comfortable conversation:

```swift
let t1 = Plan.every(1.second).do { }

let t2 = Plan.after(1.hour, repeating: 1.minute).do { }

let t3 = Plan.of(1.second, 2.minutes, 3.hours).do { }
```

#### Date-based Schedule

Configuring date-based timing tasks is the same, Schedule defines all the commonly used date time types, trying to make your writing experience intuitive and smooth::

```swift
let t1 = Plan.at(when).do { }

let t2 = Plan.every(.monday, .tuesday).at("9:00:00").do { }

let t3 = Plan.every(.september(30)).at(10, 30).do { }

let t4 = Plan.every("one month and ten days").do { }

let t5 = Plan.of(date0, date1, date2).do { }
```

#### Natural Language Parse

In addition, Schedule also supports basic natural language parsing, which greatly improves the readability of your code: 

```swift
let t1 = Plan.every("one hour and ten minutes").do { }

let t2 = Plan.every("1 hour, 5 minutes and 10 seconds").do { }

let t3 = Plan.every(.firday).at("9:00 pm").do { }

Period.registerQuantifier("many", for: 100 * 1000)
let t4 = Plan.every("many days").do { }
```

#### Mixing Rules Schedule

Schedule provides several collection operators, this means you can use them to customize your awesome rules:

```swift
/// Concat
let p0 = Plan.at(birthdate)
let p1 = Plan.every(1.year)
let birthday = p0.concat.p1
let t1 = birthday.do { 
    print("Happy birthday")
}

/// Merge
let p3 = Plan.every(.january(1)).at("8:00")
let p4 = Plan.every(.october(1)).at("9:00 AM")
let holiday = p3.merge(p4)
let t2 = holiday.do {
    print("Happy holiday")
}

/// First
let p5 = Plan.after(5.seconds).concat(Schedule.every(1.day))
let p6 = s5.first(10)

/// Until
let p7 = P.every(.monday).at(11, 12)
let p8 = p7.until(date)
```

### Creation

#### Parasitism

Schedule provides a parasitic mechanism, that allows you to handle one of the most common scenarios in a more elegant way:

```swift
Plan.every(1.second).do(host: self) {
    // do something, and cancel the task when host is deallocated.
    // this's very useful when you want to bind a task's lifetime to a controller.
}
```

#### RunLoop

The task will be executed on the current thread by default, and its implementation is based on RunLoop. So you need to ensure that the current thread has a RunLoop available. If the task is created on a child thread, you may need to run `RunLoop.current.run()`.

By default, Task will be added to `.common` mode, you can specify another mode when creating a task:

```swift
let task = Plan.every(1.second).do(mode: .default) {
    print("on default mode...")
}
```

#### DispatchQueue

You can use `queue` to specify which DispatchQueue the task will be dispatched to. In this case, the execution of the task is no longer dependent on RunLoop, you can use it safely on a child thread:

```swift
Plan.every(1.second).do(queue: .global()) {
    print("On a globle queue")
}
```

### Management

You can `suspend`, `resume`, `cancel` a task.

```swift
let task = Plan.every(1.minute).do { }

// will increase task's suspensions
task.suspend()

// will decrease task's suspensions, 
// but don't worry about excessive resumptions, I will handle these for you~
task.resume()

// cancel task, this will remove task from the internal holder, 
// in other words, will reduce task's reference count, 
// if there are no other holders, task will be released.
task.cancel()
```

#### Action

You can add more actions to a task and delete them at any time you want:

```swift
let dailyTask = Plan.every(1.day)
dailyTask.addAction {
    print("open eyes")
}
dailyTask.addAction {
    print("get up")
}
let key = dailyTask.addAction {
    print("take a shower")
}
dailyTask.removeAction(byKey: key)
```

#### TaskCenter & Tag

Tasks are automatically added to `TaskCenter.default` when they are created. You can organize tasks using tags and task center.

```swift
let plan = Plan.every(1.day)
let task0 = plan.do(queue: myTaskQueue) { }
let task1 = plan.do(queue: myTaskQueue) { }

TaskCenter.default.addTags(["database", "log"], to: task1)
TaskCenter.default.removeTag("log", from: task1)

TaskCenter.default.suspend(byTag: "log")
TaskCenter.default.resume(byTag: "log")
TaskCenter.default.cancel(byTag: "log")

TaskCenter.default.clear()

let myCenter = TaskCenter()
myCenter.add(task0)	// will remove task0 from default center.
```

#### Timeline

You can inspect the timeline of a task in real time:

```swift
let timeline = task.timeline
print(timeline.initialization)
print(timeline.firstExecution)
print(timeline.lastExecution)
print(timeline.estimatedNextExecution)
```

#### Lifetime

And specify the lifetime of task:

```swift
// will be cancelled after 10 hours.
task.setLifetime(10.hours)

// will add 1 hour to tasks lifetime 
task.addLifetime(1.hour)  

task.restOfLifetime == 11.hours
```

## Support

- iOS 10.0+ / macOS 10.14+ / tvOS 10.0+ / watchOS 3.0+
- Linux(Tested on Ubuntu 16.04)

## Installation

### CocoaPods

```ruby
# Podfile
use_frameworks!

target 'YOUR_TARGET_NAME' do
  pod 'Schedule', '~> 1.0'
end
```

### Carthage

```ruby
github "jianstm/Schedule" ~> 1.0
```

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/jianstm/Schedule", .upToNextMajor(from: "1.0.0"))
]
```

## Acknowledgement

Inspired by Dan Bader's [schedule](https://github.com/dbader/schedule)!

## Contributing

Like **Schedule**? Thank you so much! At the same time, I need your help:

### Finding Bugs

Schedule is just getting started, it is difficult to say how far the project is from bug free. If you could help the Schedule find or fix bugs that haven't been discovered yet, I would appreciate it!

### New Features

Any awesome ideas? Feel free to open an issue or submit your pull request directly!

### Documentation improvements.

Improvements to README and documentation are welcome at all times, whether typos or my lame English. For users, the documentation is sometimes much more important than the specific code implementation.

### Share

The more users the project has, the more robust the project will become, so, star! fork! and tell your friends!
