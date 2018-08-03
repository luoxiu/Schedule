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


# Schedule

⏳ Schedule 是一个羽般轻量的定时任务框架，它可以让你用一种难以置信的友好语法执行定时任务.

<p align="center"><img src="https://raw.githubusercontent.com/jianstm/Schedule/master/Images/demo.png" width="700">

</p>

## Features

- [x] ⏰ 基于时间间隔调度
- [x] 📆 基于日期调度
- [x] 🌈 自定义规则调度
- [x] 📝 自然语言周期解析
- [x] 🚦 暂停、继续、取消
- [x] 🎡 重新设置调度规则
- [x] 🏷 使用 Tag 管理任务
- [x] 🍰 添加、移除子动作
- [x] 🚔 原子操作 
- [x] 🏌 对生存时间的完全控制 
- [x] 🍻 不用再担心 RunLoop
- [x] 👻 不用再担心循环引用（当然如果你执意不用 weak self 的话）
- [x] 🍭 **难以置信的友好语法**  

### 为什么你应该用 Schedule 来代替 Timer

一表胜千言：                                                 

| 功能                                  | Timer | DispatchSourceTimer | Schedule |
| ----------------------------------------- | :---: | :-----------------: | :------: |
| ⏰ 基于时间间隔调度                 |   ✓   |          ✓          |    ✓     |
| 📆 基于日期调度                     |   ✓   |                     |    ✓     |
| 🌈 自定义规则调度                   |       |                     |    ✓     |
| 📝 自然语言周期解析           |       |                     |    ✓     |
| 🚦 暂停、继续、取消                |       |          ✓          |    ✓     |
| 🎡 重新设置调度规则                              |       |          ✓          |    ✓     |                   
| 🏷 使用 Tag 管理任务                    |       |                     |    ✓     |
| 🍰 添加、移除子动作                 |       |                     |    ✓     |
| 🚔 原子操作                        |       |                     |    ✓     |
| 🏌 对生存时间的完全控制         |       |                     |    ✓     |
| 🍭 **难以置信的友好语法**       |       |                     |    ✓     |


## 使用方法

调度一个定时任务不能更简单了：

```swift
Schedule.after(3.seconds).do {
print("3 seconds passed!")
}
```

### 基于时间间隔调度

```swift
Schedule.every(1.seconds).do { }

Schedule.after(1.hour, repeating: 1.minute).do { }

Schedule.of(1.second, 2.minutes, 3.hours).do { }
```


### 基于日期调度

```swift
Schedule.at(when).do { }

Schedule.every(.monday, .tuesday).at("9:00:00").do { }

Schedule.every(.september(30)).at(10, 30).do { }

Schedule.every("one month and ten days").do { }

Schedule.of(date0, date1, date2).do { }
```


### 自定义规则调度

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

### 自然语言周期解析

```swift
Schedule.every("one hour and ten minutes").do { }

Schedule.every("1 hour, 5 minutes and 10 seconds").do { }
```

### 任务管理

使用 Schedule，你就不再需要担心 task 的引用管理了。所有 tasks 都被内部持有，它们不会被提前释放，除非你显式地 cancel 它。

Schedule 还为你提供了一种更优雅的方式来处理 task 的生命周期：

```swift
Schedule.every(1.second).do(host: self) {
// do something, and cancel the task when `self` is deallocated.
}
```

#### 操作

```swift
let task = Schedule.every(1.day).do { }

task.suspend()
task.resume()
task.cancel()    // will remove internally held reference of this task
```

#### 标签

你可以通过 `tag` 来组织 tasks，`queue` 定义了这个 task 将会被派发到哪里：

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

`Aciton` 是一个更小的任务单元，一个 task 其实是由一系列 action 组成的： 

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

你可以获取当前 task 的时间线：

```swift
let timeline = task.timeline
print(timeline.firstExecution)
print(timeline.lastExecution)
print(timeline.estimatedNextExecution)
```

也可是设置 task 的寿命：

```swift
task.setLifetime(10.hours)  // will cancel this task after 10 hours
task.addLifetime(1.hours)
task.restOfLifetime == 11.hours
```

## 需求

- Swift 4.x
- 支持所有苹果平台（iOS，macOS，watchOS，tvOS)！
- 而且因为没有用到任何 `NS` 类，所以 linux 应该也支持哦！

## 安装

### Cocoapods

```ruby
# Podfile
use_frameworks!

target 'YOUR_TARGET_NAME' do
pod 'Schedule'
end
```

把 YOUR_TARGET_NAME 替换成你的项目名，然后执行：

```sh
$ pod install
```

### Carthage

把下行加到 Cartfile 里：

```
github "jianstm/Schedule"
```

然后执行：

```sh
$ carthage update
```


### Swift Package Manager

```swift
dependencies: [
.package(url: "https://github.com/jianstm/Schedule", .upToNextMinor("0.0.0"))
]
```

然后执行：

```sh
$ swift build
```

## 贡献

请畅所欲言你的任何建议或意见！

---

喜欢 **Schedule** 吗？给我一个 star 然后告诉你的朋友们吧！
