<p align="center">
<img src="https://raw.githubusercontent.com/jianstm/Schedule/master/logo.png" width="700">
</p>

<p align="center">

[![Build Status](https://travis-ci.org/jianstm/Schedule.svg?branch=master)](https://travis-ci.org/jianstm/Schedule)
[![codecov](https://codecov.io/gh/jianstm/Schedule/branch/master/graph/badge.svg)](https://codecov.io/gh/jianstm/Schedule)
<img src="https://img.shields.io/badge/version-0.1.0-orange.svg">
<img src="https://img.shields.io/badge/support-CocoaPods%20%7C%20Carthage%20%7C%20SwiftPM-brightgreen.svg">
<img src="https://img.shields.io/badge/platform-iOS%20%7C%20macOS%20%7C%20watchOS%20%7C%20tvOS%20%7C%20Linux-lightgrey.svg">
</p>

# Schedule([简体中文](README.zh_cn.md))

⏳ Schedule is a lightweight task scheduler for Swift. It allows you run timed tasks using an incredibly human-friendly syntax.

<p align="center">
<img src="https://raw.githubusercontent.com/jianstm/Schedule/master/demo.png" width="700">
</p>

## Features

- [x] Variety of Scheduling Rules 
- [x] Suspend, Resume, Cancel
- [x] Reschedule
- [x] Tag-based Task Management
- [x] Child-action Add/Remove
- [x] Natural Language Parse
- [x] Thread Safe
- [x] Full Control Over the Life Cycle 
- [x] 95%+ Test Coverage
- [x] Extensive Documention(All Public Types & Methods)
- [x] Linux Support(Tested on Ubuntu 16.04)
- [x] **Incredibly Human-friendly APIs**  

### Why You Should Use Schedule

A chart is worth a thousand words:

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
| 🚀 Realtime Timeline Inspect | | | ✓ |
| 🎯 Lifetime Specify | | | ✓ |
| 🍭 **Incredibly Human Friendly APIs** | | | ✓ |

## Usage

Scheduling a task has never been so simple and intuitive:

```swift
Schedule.after(3.seconds).do {
    print("3 seconds passed!")
}
```

### Schedule

#### Interval-based Schedule

Schedule uses a built-in type `Interval` to configure timed tasks, so there is no pollution of the namespace. The elegant constructors make the entire configuration work like an easy conversation with an old firend:

```swift
Schedule.every(1.second).do { }

Schedule.after(1.hour, repeating: 1.minute).do { }

Schedule.of(1.second, 2.minutes, 3.hours).do { }
```

#### Date-based Schedule

Configuring date-based timing tasks is the same:

```swift
Schedule.at(when).do { }

Schedule.every(.monday, .tuesday).at("9:00:00").do { }

Schedule.every(.september(30)).at(10, 30).do { }

Schedule.every("one month and ten days").do { }

Schedule.of(date0, date1, date2).do { }
```

#### Natural Language Parse

And, Schedule supports basic natural language parsing, which greatly improves the readability of your code: 

```swift
Schedule.every("one hour and ten minutes").do { }

Schedule.every("1 hour, 5 minutes and 10 seconds").do { }

Schedule.every(.firday).at("9:00 pm").do { }

// Extensions
Period.registerQuantifier("many", for: 100 * 1000)
let period = Period("many days")
```

#### Mixing Rules Schedule

Schedule provides several collection operators, this means you can use them to customize your awesome rules:

```swift
/// Concat
let s0 = Schedule.at(birthdate)
let s1 = Schedule.every(1.year)
let birthdaySchedule = s0.concat.s1
birthdaySchedule.do { 
    print("Happy birthday")
}

/// Merge
let s3 = Schedule.every(.january(1)).at("8:00")
let s4 = Schedule.every(.october(1)).at("9:00 AM")
let holiday = s3.merge(s4)
holidaySchedule.do {
    print("Happy holiday")
}

/// First
let s5 = Schedule.after(5.seconds).concat(Schedule.every(1.day))
let s6 = s5.first(10)

/// Until
let s7 = Schedule.every(.monday).at(11, 12)
let s8 = s7.until(date)
```

### Management

In schedule, every newly created task is automatically held by an internal global variable and will not be released until you cancel it actively. So you don't have to add variables to your controller and write nonsense like `weak var timer: Timer`, `self.timer = timer`:

```swift
let task = Schedule.every(1.minute).do { }

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

#### Parasitism

Schedule provides a parasitic mechanism, that allows you to handle one of the most common scenarios in a more elegant way:

```swift
Schedule.every(1.second).do(host: self) {
    // do something, and cancel the task when host is deallocated.
    // this's very useful when you want to bind a task's lifetime to a controller.
}
```

#### Action

You can add more actions to a task and delete them at any time you want:

```swift
let dailyTask = Schedule.every(1.day)
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
let s = Schedule.every(1.day)
let task0 = s.do(queue: myTaskQueue, tag: "log") { }
let task1 = s.do(queue: myTaskQueue, tag: "log") { }

task0.addTag("database")
task1.removeTag("log")

Task.suspend(byTag: "log")
Task.resume(byTag: "log")
Task.cancel(byTag: "log")
```

#### Timeline

You can inspect the timeline of a task in real time:

```swift
let timeline = task.timeline
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

## Requirements

- Swift 4.x
- iOS 8.0+ / macOS 10.10+ / tvOS 9.0+ / watchOS 2.0+
- Linux(Tested on Ubuntu 16.04) 

## Installation

### CocoaPods

```ruby
# Podfile
use_frameworks!

target 'YOUR_TARGET_NAME' do
  pod 'Schedule'
end
```

### Carthage

```
github "jianstm/Schedule"
```

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/jianstm/Schedule", .upToNextMinor("0.1.0"))
]
```

## Contributing

Like **Schedule**? Thank you so much! At the same time, I need your help:

### Finding Bugs

Schedule is just getting started. Although I had tried to write a lot of test cases(over 95%), it is still difficult to say how far the project is from bug free. If you could help the Schedule find or even fix bugs that haven't been discovered yet, I would appreciate it!

### New Features

Any awesome ideas? Feel free to open an issue or submit your pull request directly!

### Documentation improvements.

Improvements to README and documentation are welcome at all times. For users, the documentation is sometimes much more important than the specific code implementation.

### Share

The more users the project has, the more robust the project will become, so, star! fork! and tell your friends!
