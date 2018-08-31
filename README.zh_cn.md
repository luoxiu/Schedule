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

# Schedule

Schedule 是一个轻量级的调度框架，它可以让你用难以置信的友好语法执行定时任务.

<p align="center">
<img src="https://raw.githubusercontent.com/jianstm/Schedule/master/demo.png" width="700">
</p>

## Features

- [x] 多种规则调度
- [x] 暂停、继续、取消
- [x] 重置规则
- [x] 基于 Tag 的任务管理
- [x] 添加、移除子动作
- [x] 自然语言解析
- [x] 线程安全
- [x] 对生命周期的全面控制
- [x] 95%+ 测试覆盖
- [x] 完善的文档（所有 public 类型和方法）
- [x] Linux Support(Tested on Ubuntu 16.04) 
- [x] **难以置信的友好语法**

### 为什么你该用 Schedule

一表胜千言：

| 功能 | Timer | DispatchSourceTimer | Schedule |
| --- | :---: | :---: | :---: |
| ⏰ 基于时间间隔调度 | ✓ | ✓ | ✓ |
| 📆 基于日期调度 | ✓ | | ✓ |
| 🌈 自定义规则调度 | | | ✓ |
| 🚦 暂停、继续、取消 | | ✓ | ✓ |
| 🎡 重置规则 | | ✓ | ✓ |
| 🏷 基于 Tag 的任务管理 | | | ✓ |
| 🍰 添加、移除子动作 | | | ✓ |
| 📝 自然语言解析 | | | ✓ |
| 🚔 原子操作 | | | ✓ |
| 🚀 实时观察时间线 | | | ✓ |
| 🏌 寿命设置 | | | ✓ |
| 🍭 **难以置信的友好语法** | | | ✓ |

## Usages

调度一个定时任务从未如此简单直观：

```swift
Schedule.after(3.seconds).do {
    print("3 seconds passed!")
}
```

### 调度

#### 基于时间间隔调度

Schedule 使用内置的 `Interval` 类型来配置定时任务，所以你不用担心对你的命名空间的污染。优雅的构造方式使整个配置过程就像一场与老友的对话：

```swift
Schedule.every(1.second).do { }

Schedule.after(1.hour, repeating: 1.minute).do { }

Schedule.of(1.second, 2.minutes, 3.hours).do { }
```

#### 基于日期调度

配置基于日期的任务调度同样如此：

```swift
Schedule.at(when).do { }

Schedule.every(.monday, .tuesday).at("9:00:00").do { }

Schedule.every(.september(30)).at(10, 30).do { }

Schedule.every("one month and ten days").do { }

Schedule.of(date0, date1, date2).do { }
```

#### 自然语言解析

同时，Schedule 支持基础的自然语言解析，这大大增加了你的代码的可读性：

```swift
Schedule.every("one hour and ten minutes").do { }

Schedule.every("1 hour, 5 minutes and 10 seconds").do { }

Schedule.every(.firday).at("9:00 pm").do { }

Period.registerQuantifier("many", for: 100 * 1000)
Schedule.every("many days").do { }
```

#### 自定义规则调度

Schedule 提供了几个简单的集合操作符，这意味着你可以使用它们定制属于你的强大规则：

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

### 管理

在 Schedule 里，每一个新创建的 task 都会被一个内部的全局变量自动持有，除非你显式地 cancel 它们，否则它们不会被提前释放。也就是说你不用再在控制器里写那些诸如 `weak var timer: Timer`, `self.timer = timer` 之类的啰唆代码了：

```swift
let task = Schedule.every(1.minute).do { }

// 会增加 task 的暂停计数
task.suspend()

// 会减少 task 的暂停计数，不过不用担心过度减少，
// 我会帮你处理好这些~
task.resume()

// 取消任务，这会把任务从内部持有者那儿移除
// 也就是说，会减少 task 的引用计数
// 如果没有其它持有者的话，这个任务就会被释放
task.cancel()
```

#### 寄生

Schedule 提供了一种寄生机制，它可以让你以一种更优雅的方式处理 task 的生命周期：

```swift
Schedule.every(1.second).do(host: self) {
	// do something, task 会在 host 被 deallocated 后自动被 cancel
	// 这在你想要把一个 task 的生命周期绑定到控制器上时非常有用
}
```

#### 子动作

你可以添加更多的 action 到一个 task 上去，并在任意时刻移除它们：

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

你可以用 tag 来组织 tasks，用 queue 指定这个 task 派发到哪里：

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

#### 时间线

你可以实时地观察 task 的当前时间线：

```swift
let timeline = task.timeline
print(timeline.firstExecution)
print(timeline.lastExecution)
print(timeline.estimatedNextExecution)
```

#### 寿命

也可以精确地设置 task 的寿命：

```swift
// 会再 10 小时后取消该 task
task.setLifetime(10.hours)

// 会给该 task 的寿命增加 1 小时
task.addLifetime(1.hour)

task.restOfLifetime == 11.hours
```

## 支持

- Swift 4.x
- iOS 8.0+ / macOS 10.10+ / tvOS 9.0+ / watchOS 2.0+
- Linux(Tested on Ubuntu 16.04) 

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
	.package(url: "https://github.com/jianstm/Schedule", .upToNextMinor("0.1.0"))
]
```

## 致谢

API 的设计灵感来自于 Dan Bader 的作品 [schedule](https://github.com/dbader/schedule) 和 ruby 的语法！

## 贡献

喜欢 **Schedule** 吗？谢谢！与此同时我需要你的帮助：

### 找 Bugs

Schedule 还是一个非常年轻的项目，即使我已经尽力写了大量的测试用例（超过 95%），但还是很难说项目离 bug free 还有多远。如果你能帮 Schedule 找到甚至解决还没被发现的 bug 的话，我将感激不尽！

### 新功能

有超酷的想法吗？尽管在 issue 里分享出来，或者直接提交你的 Pull Request！

### 改善文档

对 README 或者文档注释的改善建议在任何时候都非常欢迎。对使用者来说，文档有时要比具体的代码实现要重要得多。

### 分享

无疑，用的人越多，项目就会变得越健壮，所以，star！fork！然后告诉你的朋友们吧！