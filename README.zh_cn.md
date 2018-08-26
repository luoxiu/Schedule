<p align="center">
<img src="https://raw.githubusercontent.com/jianstm/Schedule/master/Images/logo.png" width="700">
</p>

<p align="center">

[![Build Status](https://travis-ci.org/jianstm/Schedule.svg?branch=master)](https://travis-ci.org/jianstm/Schedule)
[![codecov](https://codecov.io/gh/jianstm/Schedule/branch/master/graph/badge.svg)](https://codecov.io/gh/jianstm/Schedule)
<img src="https://img.shields.io/badge/version-0.0.9-orange.svg">
<img src="https://img.shields.io/badge/support-CocoaPods%20%7C%20Carthage%20%7C%20SwiftPM-brightgreen.svg">
<img src="https://img.shields.io/badge/platform-iOS%20%7C%20macOS%20%7C%20watchOS%20%7C%20tvOS-lightgrey.svg">
</p>

# Schedule

⏳ Schedule 是一个羽量级的定时任务框架，它可以让你用一种难以置信的友好语法执行定时任务.

<p align="center">
<img src="https://raw.githubusercontent.com/jianstm/Schedule/master/Images/demo.png" width="700">
</p>

## Features

- [x] 多种规则调度
- [x] 自然语言周期解析
- [x] 暂停、继续、取消
- [x] 重置定时规则
- [x] 基于 Tag 的任务管理
- [x] 添加、移除子动作
- [x] 线程安全 
- [x] 对生命周期的完全控制 
- [x] 95%+ 测试覆盖
- [x] 完善的文档（所有 public 类型和方法）
- [x] **难以置信的友好语法**  

### 为什么你应该用 Schedule 来代替 Timer

一表胜千言：

| 功能 | Timer | DispatchSourceTimer | Schedule |
| --- | :---: | :---: | :---: |
| ⏰ 基于时间间隔调度 | ✓ | ✓ | ✓ |
| 📆 基于日期调度 | ✓ | | ✓ |
| 🌈 自定义规则调度 | | | ✓ |
| 📝 自然语言周期解析 | | | ✓ |
| 🚦 暂停、继续、取消 | | ✓ | ✓ |
| 🎡 重置定时规则 | | ✓ | ✓ |
| 🏷 使用 Tag 批量管理任务 | | | ✓ |
| 🍰 添加、移除子动作 | | | ✓ |
| 🚔 原子操作 | | | ✓ |
| 🚀 实时观察时间线 | | | ✓ |
| 🏌 寿命控制 | | | ✓ |
| 🍭 **难以置信的友好语法** | | | ✓ |

## 使用方法

调度一个定时任务从未如此简单：

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

Schedule 提供了几个简单的集合操作符，你可以使用它们自定义属于你的定制规则：

```swift
import Schedule

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

### 自然语言周期解析

Schedule 支持简单的自然语言解析：

```swift
Schedule.every("one hour and ten minutes").do { }

Schedule.every("1 hour, 5 minutes and 10 seconds").do { }
```

### 任务管理

在 Schedule 里，每一个新创建的 task 都会被一个内部的全局变量持有，它们不会被提前释放，除非你显式地 cancel 它们。所以你不用再在控制器里写那些诸如 `weak var timer: Timer`, `self.timer = timer` 之类的啰唆代码：

```swift
let task = Schedule.every(1.minute).do { }
task.suspend()		// will increase task's suspensions
task.resume() 		// will decrease task's suspensions, but no over resume at all, I will handle this for you~
task.cancel() 		// cancel a task will remove it from the internal holder, that is, will decrease task's reference count by one, if there are no other holders, task will be released.
```

#### 寄生

Schedule 提供了一种寄生机制来帮你以一种更优雅的方式处理 task 的生命周期：

```swift
Schedule.every(1.second).do(host: self) {
	// do something, task 会在 host 被 deallocated 后自动 cancel, 这在你想要把 task  的生命周期绑定到一个控制器上时非常有用
}
```

#### Action

你可以添加更多的 action 到一个 task 上去，并在任何时刻移除它们：

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

#### 标签

你可以通过 `tag` 来组织 tasks，用 `queue` 指定这个 task 将会被派发到哪里：

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

你可以实时地获取当前 task 的时间线：

```swift
let timeline = task.timeline
print(timeline.firstExecution)
print(timeline.lastExecution)
print(timeline.estimatedNextExecution)
```

也可以设置 task 的寿命：

```swift
task.setLifetime(10.hours) // will be cancelled after 10 hours.
task.addLifetime(1.hour)  // will add 1 hour to tasks lifetime
task.restOfLifetime == 11.hours
```

## 支持

- Swift 4.x
- iOS 8.0+ / macOS 10.10+ / tvOS 9.0+ / watchOS 2.0+
- 而且因为没有用到任何 `NS` 类，所以 Linux 也应该支持啦！（还在测试中）

## 安装

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
	.package(url: "https://github.com/jianstm/Schedule", .upToNextMinor("0.0.0"))
]
```

## 贡献

Schedule 现在还是一个刚刚起步的项目，它只不过满足了我对一个好用的 Timer 的期待，如果你有任何问题或者建议，请使用 issues 畅所欲言！

> 喜欢 **Schedule** 吗？给我一个 star，然后告诉你的朋友们吧！🍻
