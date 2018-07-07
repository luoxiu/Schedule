# Schedule

⏰ A interval-based and date-based job scheduler for swift.


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

Scheduling a job can not be simplier.

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


### Job management

In genera, you don't need to care about the reference management of job. All jobs will be held by a inner shared instance `jobCenter`, so they won't be released, unless you do that yourself.


```swift
let job = Schedule.every(1.day).do { }

job.suspend()
job.resume()
job.cancel()    // will release this job
```

You also can use `tag` to organize jobs, and use `queue` to define which queue the job should be dispatched to:

```swift
let s = Schedule.every(1.day)
s.do(queue: myJobQueue, tag: "log") { }
s.do(queue: myJobQueue, tag: "log") { }

Job.suspend("log")
Job.resume("log")
Job.cancel("log")
```

## Install

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
    .package(url: "https://github.com/jianstm/Schedule", from: "0.0.2")
]
```

