# Schedule

⏰ A interval-based and date-based task scheduler for swift, with incredibly sweet apis.


## Features

- 📆 Date-based scheduling
- ⏳ Interval-based scheduling
- 📝 Mixture rules scheduling
- 🚦 Suspend, resume, cancel
- 🏷 Tag related management
- 🍻 No need to concern about runloop
- 👻 No need to concern about circular reference
- 🍭 **Sweet apis**


## Usage

Scheduling a task can not be simplier.

```swift
func heartBeat() { }
Schedule.every(0.5.seconds).do(heartBeat)
```

### Interval-based Scheduling

```swift
import Schedule

Schedule.after(3.seconds).do {
    print("hello")
}

Schedule.every(1.day).do { }

Schedule.after(1.hour, repeating: 1.minute).do { }

Schedule.of(1.second, 2.minutes, 3.hours).do { }

Schedule.from([1.second, 2.minutes, 3.hours]).do { }
```



### Date-based Scheduling

```swift
import Schedule

Schedule.at(date).do { }

Schedule.every(.monday, .tuesday).at("11:11").do { }

Schedule.every(.september(30)).at("10:00:00").do { }

Schedule.of(date0, date1, date2).do { }

Schedule.from([date0, date1, date2]).do { }
```



### Custom Scheduling

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
let s3 = Schedule.every(.january(1)).at(8, 30)
let s4 = Schedule.every(.october(1)).at(8, 30)
let holiday = s3.merge(s3)
holidaySchedule.do {
    print("Happy holiday")
}

/// count
let s5 = Schedule.after(5.seconds).concat(Schedule.every(1.day))
let s6 = s5.count(10)

/// until
let s7 = Schedule.every(.monday).at(11, 12)
let s8 = s7.until(date)
```


### Task management

In general, you don't need to care about the reference management of task. All tasks will be held by a inner shared instance of class `TaskCenter`, so they won't be released, unless you do that yourself.

#### Operation

```swift
let task = Schedule.every(1.day).do { }

task.suspend()
task.resume()
task.cancel()    // will release this task after you cancel it.
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

Aciton is minimal job unit. A task is composed of a series of actions. 

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

There is also a more elegant way to deal with task's lifecycle:

```swift
Schedule.every(1.second).do(dependOn: self) {
    // do something, and cancel the task when `self` is deallocated.
}
```

## Contribution

Feel free to criticize!

## Installation

Schedul supports all popular dependency managers.

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
    .package(url: "https://github.com/jianstm/Schedule", .exact("0.0.4"))
]
```
