<p align="center">
<img src="https://raw.githubusercontent.com/jianstm/Schedule/master/Images/logo.png" width="350">
</p>

<p align="center>A light-weight task scheduler for Swift.</p>

<p align="center">
<img src="https://img.shields.io/travis/jianstm/Schedule.svg">
<img src="https://img.shields.io/codecov/c/github/jianstm/schedule.svg">
<img src="https://img.shields.io/cocoapods/v/Schedule.svg">
<img src="https://img.shields.io/badge/Carthage-compatible-brightgreen.svg">
<img src="https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg">
<p>

# Schedule([简体中文](https://raw.githubusercontent.com/jianstm/Schedule/master/README.zh_cn.md))

⏳ Schedule is a light-weight task scheduler for Swift. It allows you run timed tasks using an incredibly human-friendly syntax.

<p align="center">
<img src="https://raw.githubusercontent.com/jianstm/Schedule/master/Images/demo.png" width="700">
</p>

## Features

- [x] ⏰ Interval-based Schedule
- [x] 📆 Date-based Schedule
- [x] 🌈 Mixing rules Schedule
- [x] 📝 Human Readable Period Parse
- [x] 🚦 Suspend, Resume, Cancel
- [x] 🎡 Reschedule
- [x] 🏷 Tag-based Management
- [x] 🍰 Child-action Add/Remove
- [x] 🚔 Atomic Operations 
- [x] 🏌 Full Control Over the Lift Time 
- [x] 🍻 No Need to Worry About Runloop
- [x] 👻 No Need to Worry About Circular Reference
- [x] 🍭 **Incredibly Human Friendly API**  

### Why should you Use Schedule Instead of Timer?

A chart is worth a thousand words:                                             

| Features                                  | Timer | DispatchSourceTimer | Schedule |
| ----------------------------------------- | :---: | :-----------------: | :------: |
| ⏰ Interval-based Schedule                 |   ✓   |          ✓          |    ✓     |
| 📆 Date-based Schedule                     |   ✓   |                     |    ✓     |
| 🌈 Mixing Rules Schedule                   |       |                     |    ✓     |
| 📝 Human Readable Period Parse           |       |                     |    ✓     |
| 🚦 Suspende/Resume, Cancel                 |       |          ✓          |    ✓     |
| 🎡 ReSchedule                              |       |          ✓          |    ✓     |                   
| 🏷 Tag-based management                    |       |                     |    ✓     |
| 🍰 Child-action Add/Remove                 |       |                     |    ✓     |
| 🚔 Atomic Operations                       |       |                     |    ✓     |
| 🏌 Full Control Over the Life Time         |       |                     |    ✓     |
| 🍭 **Incredibly Human Friendly API**       |       |                     |    ✓     |

## Usage

Scheduling a task can't be simplier:

```swift
Schedule.after(3.seconds).do {
    print("3 seconds passed!")
}
```

### Interval-based Schedule

```swift
Schedule.every(1.seconds).do { }

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

```swift
import Schedule

/// concat
let s0 = Schedule.at(birthdate)
let s1 = Schedule.every(1.year)
let birthdaySchedule = s0.concat.s1
birthdaySchedule.do { 
    print("Happy birthday")
}

/// merge
let s3 = Schedule.every(.january(1)).at("8:00")
let s4 = Schedule.every(.october(1)).at("9:00 AM")
let holiday = s3.merge(s4)
holidaySchedule.do {
    print("Happy holiday")
}

/// first
let s5 = Schedule.after(5.seconds).concat(Schedule.every(1.day))
let s6 = s5.first(10)

/// until
let s7 = Schedule.every(.monday).at(11, 12)
let s8 = s7.until(date)
```

### Human Readable Period Parse

```swift
Schedule.every("one hour and ten minutes").do { }

Schedule.every("1 hour, 5 minutes and 10 seconds").do { }
```

### Task Management

In general, you don't need to worry about reference management of the task any more. All tasks will be retained internally, so they won't be released, unless you do it yourself.

Schedule lets you handle a task's lifecycle with a more elegant way:

```swift
Schedule.every(1.second).do(host: self) {
    // do something, and cancel the task when `self` is deallocated.
}
```

#### Handle

```swift
let task = Schedule.every(1.day).do { }

task.suspend()
task.resume()
task.cancel()    // will remove internally held reference of this task
```

#### Tag

You can organize tasks with `tag`, and use `queue` to define where the task should be dispatched:

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

#### Action

`Aciton` is smaller unit of `Task`, A task is composed of a series of actions. 

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

#### Lifecycle

You can get the current timeline of the task:

```swift
let timeline = task.timeline
print(timeline.firstExecution)
print(timeline.lastExecution)
print(timeline.estimatedNextExecution)
```

You also can specify task's lifetime:

```swift
task.setLifetime(10.hours)  // will cancel this task after 10 hours
task.addLifetime(1.hours)
task.restOfLifetime == 11.hours
```

## Requirements

- Swift 4.x
- All Apple platforms are supported!
- And since there is no use of `NS` class, it should supports linux, too!

## Installation

### Cocoapods

```ruby
# Podfile
use_frameworks!

target 'YOUR_TARGET_NAME' do
    pod 'Schedule'
end
```

Replace YOUR_TARGET_NAME and then run:

```sh
$ pod install
```

### Carthage

Add this to Cartfile

```
github "jianstm/Schedule"
```

Then run:

```sh
$ carthage update
```

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/jianstm/Schedule", .upToNextMinor("0.0.0"))
]
```

Then run:

```sh
$ swift build
```

## Contributing

Feel free to criticize!

---

Like **Schedule**? Star me then tell your friends!
