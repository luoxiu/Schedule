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
- [x] Tag-based Management
- [x] Child-action Add/Remove
- [x] Human Readable Period Parse
- [x] Thread safe
- [x] Full Control Over the LifeCycle 
- [x] 95%+ Test Coverage
- [x] Extensive Documention(All Public Types & Methods)
- [x] Linux Support(Test on Ubuntu 16.04) 
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
| 🏷 Tag-based Management | | | ✓ |
| 🍰 Child-action Add/Remove | | | ✓ |
| 📝 Human Readable Period Parse | | | ✓ |
| 🚔 Atomic Operations | | | ✓ |
| 🚀 Realtime Timeline Inspect | | | ✓ |
| 🎯 Lifetime Assign | | | ✓ |
| 🍭 **Incredibly Human Friendly APIs** | | | ✓ |

## Usage

Scheduling a task has never been so easy and intuitive:

```swift
Schedule.after(3.seconds).do {
    print("3 seconds passed!")
}
```

### Interval-based Schedule

```swift
Schedule.every(1.second).do { }

Schedule.after(1.hour, repeating: 1.minute).do { }

Schedule.of(1.second, 2.minutes, 3.hours).do { }
```

### Date-based Schedule

```swift
Schedule.at(when).do { }

Schedule.every(.monday, .tuesday).at("9:00:00").do { }

Schedule.every(.september(30)).at(10, 30).do { }

Schedule.every("one month and ten days").do { }

Schedule.of(date0, date1, date2).do { }
```

### Mixing Rules Schedule

Schedule provides several collection operators, so you can use them to customize your own awesome rules:

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

### Human Readable Period Parse

Schedule supports simple natural language parsing: 

```swift
Schedule.every("one hour and ten minutes").do { }

Schedule.every("1 hour, 5 minutes and 10 seconds").do { }

Period.registerQuantifier("many", for: 100 * 1000)
let period = Period("many days")
```

### Task Management

In schedule, every newly created task will be automatically held by an internal global variable and will not be released until you actively cancel it. So you don't have to add variables to the controller and write nonsense like `weak var timer: Timer`, `self.timer = timer`:

```swift
let task = Schedule.every(1.minute).do { }
task.suspend()		// will increase task's suspensions
task.resume() 		// will decrease task's suspensions, but no over resume at all, I will handle this for you~
task.cancel() 		// cancel a task will remove it from the internal holder, that is, will decrease task's reference count by one, if there are no other holders, task will be released.
```

#### Parasitism

Schedule provides parasitic mechanism to handle one of the most common scenarios in a more elegant way:

```swift
Schedule.every(1.second).do(host: self) {
    // do something, and cancel the task when `self` is deallocated, it's very useful when you want to bind a task's lifetime to a controller.
}
```

#### Action

You can add more actions to the same task and delete them at any time you want:

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

You can organize tasks with tag, and use queue to define to where the task should be dispatched:

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

#### Lifecycle

You can inspect the life cycle of task in real time:

```swift
let timeline = task.timeline
print(timeline.firstExecution)
print(timeline.lastExecution)
print(timeline.estimatedNextExecution)
```

And assign task’s lifetime:

```swift
task.setLifetime(10.hours) // will be cancelled after 10 hours.
task.addLifetime(1.hour)  // will add 1 hour to tasks lifetime
task.restOfLifetime == 11.hours
```

## Requirements

- Swift 4.x
- iOS 8.0+ / macOS 10.10+ / tvOS 9.0+ / watchOS 2.0+
- Linux Support(Test on Ubuntu 16.04) 

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

Like **Schedule**? Thank you! At the same time, I need your help:

### Find Bugs

Schedule is a very nascent project for now. Even though I had tried to write a lot of test cases, it is still difficult to say how far the project is from bug free. If you could help the Schedule find or even fix bugs that haven't been discovered yet, I would appreciate it.

### New Features

Got some awesome ideas? Feel free to open an issue or submit your pull request directly!

### Improve Documentaion

Improvements to the README or documentation are welcome at all times. For users, the documentation is much more important than the specific code implementation.

### Share

The more users the project has, the more robust the project will become, so - star! fork! and tell your friends!