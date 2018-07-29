# Schedule

![travis](https://img.shields.io/travis/jianstm/Schedule.svg)
![codecov](https://img.shields.io/codecov/c/github/jianstm/schedule.svg)
![platform](https://img.shields.io/badge/platforms-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS-333333.svg)
![cocoapods](https://img.shields.io/cocoapods/v/Schedule.svg)
![carthage](https://img.shields.io/badge/Carthage-compatible-brightgreen.svg)
![swift-package-manager](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)

⏳ An interval-based and date-based task scheduler for swift, with incredibly sweet api.

## Features

- 📆 Date-based scheduling
- ⏰ Interval-based scheduling
- 🌈 Mixture rules
- 📝 Human readable datetime parsing
- 🚦 Suspend, resume, cancel
- 🏷 Tag-based management
- 🍰 Action appending/removing
- 🚔 Thread safe
- 🍻 No need to concern about runloop
- 👻 No need to concern about circular reference
- 🍭 **Incredibly Sweet API**


## Usage

Scheduling a task can not be simplier.

```swift
Schedule.after(3.seconds).do {
	print("elapsed!")
}
```

### Interval-based Scheduling

```swift
Schedule.every(1.seconds).do { }

Schedule.after(1.hour, repeating: 1.minute).do { }

Schedule.of(1.second, 2.minutes, 3.hours).do { }
```


### Date-based Scheduling

```swift
import Schedule

Schedule.at(when).do { }

Schedule.every(.monday, .tuesday).at("9:00:00").do { }

Schedule.every(.september(30)).at(10, 30).do { }

Schedule.every("one month and ten days").do { }

Schedule.of(date0, date1, date2).do { }
```


### Mixture rules

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
let holiday = s3.merge(s3)
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

### Human readable datetime parsing

```swift
Schedule.every("one hour and ten minutes").do { }
```

### Task management

In general, you don't need to concern about the reference management of task. All tasks will be retained internally, so they won't be released, unless you do it yourself.

There is a more elegant way to deal with task's lifecycle:

```swift
Schedule.every(1.second).do(host: self) {
    // do something, and cancel the task when `self` is deallocated.
}
```

#### Manipulation

```swift
let task = Schedule.every(1.day).do { }

task.suspend()
task.resume()
task.cancel()    // will decrease this task's ref count.
```

#### Tag

You also can use `tag` to organize tasks, and use `queue` to define which queue the task should be dispatched to:

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

`Aciton` is minimal job unit. A task is composed of a series of actions. 

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
task.setLifetime(10.hours)  // will be cancelled after 10 hours.
task.addLifetime(1.hours)
task.restOfLifetime == 11.hours
```

## Installation

Schedule supports all popular dependency managers.

### Cocoapods

```ruby
pod 'Schedule'
```

### Carthage

```swift
github "jianstm/Schedule"
```

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/jianstm/Schedule", .upToNextMinor("0.0.0"))
]
```

## Contributing

Feel free to criticize! Any suggestion is welcome!

> Like **Schedule**? Star me and tell your friends!
