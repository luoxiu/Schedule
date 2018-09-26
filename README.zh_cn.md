# Schedule

<p align="center">

[![Build Status](https://travis-ci.org/jianstm/Schedule.svg?branch=master)](https://travis-ci.org/jianstm/Schedule)
[![codecov](https://codecov.io/gh/jianstm/Schedule/branch/master/graph/badge.svg)](https://codecov.io/gh/jianstm/Schedule)
<img src="https://img.shields.io/badge/version-0.1.0-orange.svg">
<img src="https://img.shields.io/badge/support-CocoaPods%20%7C%20Carthage%20%7C%20SwiftPM-brightgreen.svg">
<img src="https://img.shields.io/badge/platform-iOS%20%7C%20macOS%20%7C%20watchOS%20%7C%20tvOS%20%7C%20Linux-lightgrey.svg">
</p>

Schedule 是一个轻量级的调度框架，它能让你用难以置信的友好语法执行定时任务。

<p align="center">
<img src="https://raw.githubusercontent.com/jianstm/Schedule/master/assets/demo.png" width="700">
</p>

## 功能

- [x] 多种调度规则
- [x] 暂停、继续、取消
- [x] 重置调度规则
- [x] 基于 tag 的任务管理
- [x] 添加、移除子动作
- [x] 自然语言解析
- [x] 原子操作
- [x] 对生命周期的完全控制
- [x] 95%+ 测试覆盖
- [x] 完善的文档（所有 public 类型和方法）
- [x] 支持 Linux(通过 Ubuntu 16.04 测试) 

### 为什么你该用 Schedule

| 功能 | Timer | DispatchSourceTimer | Schedule |
| --- | :---: | :---: | :---: |
| ⏰ 基于时间间隔调度 | ✓ | ✓ | ✓ |
| 📆 基于日期调度 | ✓ | | ✓ |
| 🌈 自定义规则调度 | | | ✓ |
| 🚦 暂停、继续、取消 | | ✓ | ✓ |
| 🎡 重置规则 | | ✓ | ✓ |
| 🏷 基于 tag 的任务管理 | | | ✓ |
| 🍰 添加、移除子动作 | | | ✓ |
| 📝 自然语言解析 | | | ✓ |
| 🚔 原子操作 | | | ✓ |
| 🕕 生命周期绑定 | | | ✓ |
| 🚀 实时观察时间线 | | | ✓ |
| 🏌 寿命设置 | | | ✓ |

## 用法

### 一瞥

调度一个定时任务从未如此简单直观，你要做的只有：

```swift
// 1. 定义你的计划：
let plan = Plan.after(3.seconds)

// 2. 执行你的任务：
plan.do {
    print("3 seconds passed!")
}
```

### 规则

#### 基于时间间隔调度

Schedule 使用自定义的 `Interval` 类型来配置定时任务，你不必担心对内置类型的扩展会污染你的命名空间。流畅的构造方法让配置像一场舒服的对话：

```swift
Plan.every(1.second).do { }

Plan.after(1.hour, repeating: 1.minute).do { }

Plan.of(1.second, 2.minutes, 3.hours).do { }
```

#### 基于日期调度

配置基于日期的调度同样如此，Schedule 定义了所有常用的日期类型，尽力让你的书写直观、流畅：

```swift
Plan.at(when).do { }

Plan.every(.monday, .tuesday).at("9:00:00").do { }

Plan.every(.september(30)).at(10, 30).do { }

Plan.every("one month and ten days").do { }

Plan.of(date0, date1, date2).do { }
```

#### 自然语言解析

除此之外，Schedule 还支持基础的自然语言解析，这大大增强了你的代码的可读性：

```swift
Plan.every("one hour and ten minutes").do { }

Plan.every("1 hour, 5 minutes and 10 seconds").do { }

Plan.every(.firday).at("9:00 pm").do { }

Period.registerQuantifier("many", for: 100 * 1000)
Plan.every("many days").do { }
```

#### 自定义规则调度

Schedule 还提供了几个简单的集合操作符，这意味着你可以使用它们定制属于你的强大规则：

```swift
/// Concat
let p0 = Plan.at(birthdate)
let p1 = Plan.every(1.year)
let birthday = p0.concat.p1
birthday.do { 
    print("Happy birthday")
}

/// Merge
let p3 = Plan.every(.january(1)).at("8:00")
let p4 = Plan.every(.october(1)).at("9:00 AM")
let holiday = p3.merge(p4)
holiday.do {
    print("Happy holiday")
}

/// First
let p5 = Plan.after(5.seconds).concat(Schedule.every(1.day))
let p6 = s5.first(10)

/// Until
let p7 = P.every(.monday).at(11, 12)
let p8 = p7.until(date)
```

### 创建

#### 寄生

Schedule 提供了一种寄生机制，它让你可以以一种更优雅的方式处理 task 的生命周期：

```swift
Plan.every(1.second).do(host: self) {
    // task 会在 host 被 deallocated 后自动被 cancel
    // 这在你想要把一个 task 的生命周期绑定到控制器上时非常有用
}
```

#### RunLoop

Task 默认会在当前线程上执行，它的实现依赖于 RunLoop，所以你需要保证当前线程有一个可用的 RunLoop。如果 task 的创建在子线程上，你可能需要执行 `RunLoop.current.run()`。默认情况下， task 会被添加到 `.common` mode 上，你可以在创建 task 时指定其它 mode：

```swift
Plan.every(1.second).do(mode: .default) {
    print("on default mode...")
}
```

#### DispatchQueue

你也可以使用 queue 来指定 task 会被派发到哪个 DispatchQueue 上，这时，task 的执行不再依赖于 RunLoop，意味着你可以放心地子线程上使用：

```swift
Plan.every(1.second).do(queue: .global()) {
    print("On a globle queue")
}
```

### 管理

在 Schedule 里，每一个新创建的 task 都会被一个内部的全局变量自动持有，除非你显式地 cancel 它们，否则它们不会被提前释放。也就是说你不用再在控制器里写那些诸如 `weak var timer: Timer`, `self.timer = timer` 之类的啰唆代码了：

```swift
let task = Plan.every(1.minute).do { }

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

#### 子动作

你可以添加更多的 action 到一个 task 上去，并在任意时刻移除它们：

```swift
let dailyTask = Plan.every(1.day)
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
let s = Plan.every(1.day)
let task0 = s.do(queue: myTaskQueue) { }
let task1 = s.do(queue: myTaskQueue) { }

task0.addTag("database")
task1.addTags("database", "log")
task1.removeTag("log")

Task.suspend(byTag: "log")
Task.resume(byTag: "log")
Task.cancel(byTag: "log")
```

#### 时间线

你可以实时地观察 task 的当前时间线：

```swift
let timeline = task.timeline
print(timeline.initialization)
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

- iOS 8.0+ / macOS 10.10+ / tvOS 9.0+ / watchOS 2.0+
- Linux(Tested on Ubuntu 16.04)

## 安装

### CocoaPods

```ruby
# Podfile
use_frameworks!

target 'YOUR_TARGET_NAME' do
  pod 'Schedule', '~> 1.0'
end
```

### Carthage

```ruby
github "jianstm/Schedule" ~> 1.0
```

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/jianstm/Schedule", .upToNextMajor("1.0.0"))
]
```

## 致谢

项目灵感来自于 Dan Bader 的 [schedule](https://github.com/dbader/schedule)！语法设计深受 Ruby 影响!

## 贡献

喜欢 **Schedule** 吗？谢谢！与此同时我需要你的帮助：

### 找 Bugs

Schedule 还是一个非常年轻的项目，很难说项目离 bug free 还有多远。如果你能帮 Schedule 找到或者解决还没被发现的 bug 的话，我将感激不尽！

### 新功能

对项目有什么新的想法吗？尽管在 issue 里分享出来，或者你也可以直接提交你的 Pull Request！

### 改善文档

对 README 或者文档注释的改善建议在任何时候都非常欢迎，无论是错别字还是纠正我的蹩脚英文。对使用者来说，有时文档要比具体的代码实现要重要得多。

### 分享

无疑，用的人越多，项目就会变得越健壮，所以，star！fork！然后告诉你的朋友们吧！