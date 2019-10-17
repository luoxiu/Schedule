# Schedule

<p align="center">
<a href="https://github.com/luoxiu/Schedule/releases">
  <img src="https://img.shields.io/cocoapods/v/Schedule.svg">
</a>
<img src="https://img.shields.io/travis/luoxiu/Schedule.svg">
<img src="https://img.shields.io/codecov/c/github/luoxiu/Schedule.svg">
<img src="https://img.shields.io/badge/support-CocoaPods%20%7C%20Carthage%20%7C%20SwiftPM-brightgreen.svg">
<img src="https://img.shields.io/cocoapods/p/Schedule.svg">
<img src="https://img.shields.io/github/license/luoxiu/Schedule.svg">
</p>

Schedule 是一个用 Swift 编写的定时任务调度器，它能让你用优雅、直观的语法执行定时任务。

<p align="center">
<img src="assets/demo.png" width="700">
</p>

## 功能

- [x] 优雅，直观的 API
- [x] 丰富的预置规则
- [x] 强大的管理机制
- [x] 细致的执行记录
- [x] 线程安全
- [x] 完整的文档
- [x] ~100% 的测试覆盖

### 为什么你该使用 Schedule，而不是……

| 功能 | Timer | DispatchSourceTimer | Schedule |
| --- | :---: | :---: | :---: |
| ⏰ 基于时间间隔调度 | ✓ | ✓ | ✓ |
| 📆 基于日期调度 | ✓ | | ✓ |
| 🌈 组合计划调度 | | | ✓ |
| 🗣️ 自然语言解析 | | | ✓ |
| 🏷 批任务管理 | | | ✓ |
| 📝 执行记录 | | | ✓ |
| 🎡 规则重置 | | ✓ | ✓ |
| 🚦 暂停、继续、取消 | | ✓ | ✓ |
| 🍰 子动作 | | | ✓ |

## 用法

### 一瞥

调度一个定时任务从未如此优雅、直观，你只需要：

```swift
// 1. 定义你的计划：
let plan = Plan.after(3.seconds)

// 2. 执行你的任务：
let task = plan.do {
    print("3 seconds passed!")
}
```

### 计划

#### 基于时间间隔调度

Schedule 的机制基于 `Plan`，而 `Plan` 的本质是一系列 `Interval`。

Schedule 通过扩展 `Int` 和 `Double` 让 `Plan` 的定义更加优雅、直观。同时，因为 `Interval` 是 Schedule 的内置类型，所以你不用担心这会对你的命名空间产生污染。

```swift
let t1 = Plan.every(1.second).do { }

let t2 = Plan.after(1.hour, repeating: 1.minute).do { }

let t3 = Plan.of(1.second, 2.minutes, 3.hours).do { }
```

#### 基于日期调度

定制基于日期的 `Plan` 同样如此，配合富有表现力的 Swift 语法，Schedule 让你的代码看起来就像一场流畅的对话。

```swift
let t1 = Plan.at(date).do { }

let t2 = Plan.every(.monday, .tuesday).at("9:00:00").do { }

let t3 = Plan.every(.september(30)).at(10, 30).do { }

let t4 = Plan.every("one month and ten days").do { }

let t5 = Plan.of(date0, date1, date2).do { }
```

#### 自然语言解析

除此之外，Schedule 还支持简单的自然语言解析。

```swift
let t1 = Plan.every("one hour and ten minutes").do { }

let t2 = Plan.every("1 hour, 5 minutes and 10 seconds").do { }

let t3 = Plan.every(.friday).at("9:00 pm").do { }

Period.registerQuantifier("many", for: 100 * 1000)
let t4 = Plan.every("many days").do { }
```

#### 组合计划调度

Schedule 提供了几个基本的集合操作符，这意味着，你可以使用它们自由组合，定制属于你的强大规则。

```swift
/// Concat
let p0 = Plan.at(birthdate)
let p1 = Plan.every(1.year)
let birthday = p0.concat.p1
let t1 = birthday.do { 
    print("Happy birthday")
}

/// Merge
let p3 = Plan.every(.january(1)).at("8:00")
let p4 = Plan.every(.october(1)).at("9:00 AM")
let holiday = p3.merge(p4)
let t2 = holiday.do {
    print("Happy holiday")
}

/// First
let p5 = Plan.after(5.seconds).concat(Schedule.every(1.day))
let p6 = s5.first(10)

/// Until
let p7 = P.every(.monday).at(11, 12)
let p8 = p7.until(date)
```

### 管理

#### DispatchQueue

调用 `plan.do` 来调度定时任务时，你可以使用 `queue` 来指定当时间到时，task 会被派发到哪个 `DispatchQueue` 上。这个操作不像 `Timer` 那样依赖 `RunLoop`，所以你可以在任意线程上使用它。

```swift
let task = Plan.every(1.second).do(queue: .global()) {
    print("On a globle queue")
}
```

#### RunLoop

如果没有指定 `queue`，Schedule 会使用 `RunLoop` 来调度 task，这时，task 会在当前线程上执行。**要注意**，和同样基于 `RunLoop` 的 `Timer` 一样，你需要保证当前线程有一个**可用**的 `RunLoop`。默认情况下， task 会被添加到 `.common` mode 上，你可以在创建 task 时指定其它 mode。

```swift
let task = Plan.every(1.second).do(mode: .default) {
    print("on default mode...")
}
```

#### Timeline

你可以使用以下属性实时地观察 task 的执行记录。

```swift
task.creationDate

task.executionHistory

task.firstExecutionDate
task.lastExecutionDate

task.estimatedNextExecutionDate
```

#### TaskCenter 和 Tag

task 默认会被自动添加到 `TaskCenter.default` 上，你可以使用 tag 配合 taskCenter 来组织 tasks：

```swift
let plan = Plan.every(1.day)
let task0 = plan.do(queue: myTaskQueue) { }
let task1 = plan.do(queue: myTaskQueue) { }

TaskCenter.default.addTags(["database", "log"], to: task1)
TaskCenter.default.removeTag("log", from: task1)

TaskCenter.default.suspend(byTag: "log")
TaskCenter.default.resume(byTag: "log")
TaskCenter.default.cancel(byTag: "log")

TaskCenter.default.removeAll()

let myCenter = TaskCenter()
myCenter.add(task0)
```

### Suspend、Resume、Cancel

你可以 suspend，resume，cancel 一个 task。

```swift
let task = Plan.every(1.minute).do { }

// 会增加 task 的暂停计数
task.suspend()

task.suspensions == 1

// 会减少 task 的暂停计数
// 不过不用担心过度减少，我会帮你处理好这些~
task.resume()

task.suspensions == 0

// 会清零 task 的暂停计数
// 被 cancel 的 task 即使重新设置其它调度规则也不会有任何作用了
task.cancel()
```

#### 子动作

你可以添加更多的 action 到 task，并在任意时刻移除它们。

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

## 安装

### CocoaPods

```ruby
# Podfile
use_frameworks!

target 'YOUR_TARGET_NAME' do
  pod 'Schedule', '~> 2.0'
end
```

### Carthage

```
# Cartfile
github "luoxiu/Schedule" ~> 2.0
```

### Swift Package Manager

```swift
dependencies: [
    .package(
      url: "https://github.com/luoxiu/Schedule", .upToNextMajor(from: "2.0.0")
    )
]
```

## 贡献

喜欢 **Schedule** 吗？谢谢！！！

与此同时如果你想参与进来的话，你可以：

### 找 Bugs

Schedule 还是一个非常年轻的项目，如果你能帮 Schedule 找到甚至解决潜在的 bugs 的话，那就太感谢啦！

### 新功能

有一些有趣的想法？尽管在 issue 里分享出来，或者直接提交你的 Pull Request！

### 改善文档

任何时候都欢迎对 README 或者文档注释的修改建议，无论是错别字还是纠正我的蹩脚英文，🤣。

## 致谢

项目灵感来自 Dan Bader 的 [schedule](https://github.com/dbader/schedule)！
