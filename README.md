# Schedule([简体中文](README.zh_cn.md))

<p align="center">

[![Build Status](https://travis-ci.org/jianstm/Schedule.svg?branch=master)](https://travis-ci.org/jianstm/Schedule)
[![codecov](https://codecov.io/gh/jianstm/Schedule/branch/master/graph/badge.svg)](https://codecov.io/gh/jianstm/Schedule)
<img src="https://img.shields.io/badge/version-0.1.0-orange.svg">
<img src="https://img.shields.io/badge/support-CocoaPods%20%7C%20Carthage%20%7C%20SwiftPM-brightgreen.svg">
<img src="https://img.shields.io/badge/platform-iOS%20%7C%20macOS%20%7C%20watchOS%20%7C%20tvOS%20%7C%20Linux-lightgrey.svg">
</p>

Schedule is a lightweight timed tasks scheduler for Swift. It allows you run timed tasks using an incredibly human-friendly syntax.

<p align="center">
<img src="https://raw.githubusercontent.com/jianstm/Schedule/master/assets/demo.png" width="700">
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
plan.do {
    print("3 seconds passed!")
}
```

### Rules

#### Interval-based Schedule

Schedule uses a self-defined type `Interval` to configure timed tasks, so you don't have to worry about extensions of built-in type polluting your namespace. The smooth constructors make the configuration like a comfortable conversation:

```swift
Plan.every(1.second).do { }

Plan.after(1.hour, repeating: 1.minute).do { }

Plan.of(1.second, 2.minutes, 3.hours).do { }
```

#### Date-based Schedule

Configuring date-based timing tasks is the same, Schedule defines all the commonly used date time types, trying to make your writing experience intuitive and smooth::

```swift
Plan.at(when).do { }

Plan.every(.monday, .tuesday).at("9:00:00").do { }

Plan.every(.september(30)).at(10, 30).do { }

Plan.every("one month and ten days").do { }

Plan.of(date0, date1, date2).do { }
```

#### Natural Language Parse

In addition, Schedule also supports basic natural language parsing, which greatly improves the readability of your code: 

```swift
Plan.every("one hour and ten minutes").do { }

Plan.every("1 hour, 5 minutes and 10 seconds").do { }

Plan.every(.friday).at("9:00 pm").do { }

// Extensions
Period.registerQuantifier("many", for: 100 * 1000)
Plan.every("many days").do { }
```

#### Mixing Rules Schedule

Schedule provides several collection operators, this means you can use them to customize your awesome rules:

```swift
/// Concat
let p0 = Plan.at(birthdate)
let p1 = Plan.every(1.year)
let birthday = p0.concat.p1
birthday.do { 
    print("Happy birthday")
}

/// Merge
let p3 = Plan.every(.january(1)).at("8:00")
let p4 = Plan.every(.october(1)).at("9:00 AM")
let holiday = p3.merge(p4)
holiday.do {
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
Plan.every(1.second).do(mode: .default) {
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

In schedule, every newly created task is automatically held by an internal global variable and will not be released until you cancel it actively. So you don't have to add variables to your controller and write nonsense like `weak var timer: Timer`, `self.timer = timer`:

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

#### Tag

You can organize tasks with tags, and use queue to specify to where the task should be dispatched:

```swift
let s = Plan.every(1.day)
let task0 = s.do(queue: myTaskQueue) { }
let task1 = s.do(queue: myTaskQueue) { }

task0.addTag("database")
task1.addTags("database", "log")
task1.removeTag("log")

Task.suspend(byTag: "log")
Task.resume(byTag: "log")
Task.cancel(byTag: "log")
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

- iOS 8.0+ / macOS 10.10+ / tvOS 9.0+ / watchOS 2.0+
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

Inspired by Dan Bader's [schedule](https://github.com/dbader/schedule)! Syntax design is heavily influenced by Ruby!

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
