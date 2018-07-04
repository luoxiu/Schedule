# Schedule

Swift job scheduler.



## Usage

### Getting Start

Scheduling a job can not be simplier.

```swift
func job() { }
Schedule.every(1.minute).do(job)
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



## Date-based Scheduling

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
let s1 = Schedule.every(.year(1))
let birthdaySchedule = s0.concat.s1
birthdaySchedule.do { 
    print("Happy birthday")
}

/// merge
let s3 = Schedule.every(.january(1)).at(8, 30)
let s4 = Schedule.every(.october(1)).at(8, 30)
let holiday = s3.merge(s3)
holidaySchedule.do {
    print("Holiday~")
}
```



### Job management

Normally, you don't need to care about the reference management of job. All jobs will be held by a inner instance `jobCenter`, so they won't be released.

If you want everything in your control:

```swift
let job = Schedule.every(1.day).do { }

job.suspend() 	// will suspend job, it won't change job's schedule
job.resume()	// will resume the suspended job, it won't change job's schedule
job.cancel()	// will cancel job, then job will be released after variable `job` is gone
```

You also can use `tag` to organize jobs, and use `queue` to define which queue  the job should be dispatched to:

```swift
Schedule.every(1.day).do(queue: myJobQueue, tag: "remind me") { }

Job.suspend("remind me")  	// will suspend all jobs with this tag
Job.resume("remind me")		// will resume all jobs with this tag
Job.cancel("remind me")		// will cancel all jobs with this tag
```