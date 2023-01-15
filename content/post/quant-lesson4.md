+++
author = "zach zhou"
title = "量化交易 Lesson 4 Opening Range Breakout"
date = "2023-01-15"
description = "Lesson 4 Opening Range Breakout"
tags = [
    "quant",
]
+++
## Lesson 4 Opening Range Breakout

`Opening Range Breakout` 即开盘区间突破，ORB策略
在这里给出策略的分析定义（还不是太懂） https://www.jianshu.com/p/a2d7f12cc471

大致理解下，基于开盘价做多头止损和空头止损策略

在这个策略的开始需要：start by consolidating the first 30 minutes of data（合并前30分钟的数据）

定义`Consolidators` ：将更小的数据点合并到大的区间（是对连续数据按照时间区间进行离散化？）

```python
# Receive consolidated data with a timedelta
# parameter and OnDataConsolidated event handler
# 参数包括：symbol，时间区间，eventHandler函数
self.Consolidate("SPY", timedelta(minutes=45), self.OnDataConsolidated)
```

`Consolidators` 处理的是将小的数据进行聚合，eventHandler函数用来对聚合后的数据进行处理

`Consolidators` 返回的bar 分好几个类型，在上述例子中返回的是 `TradeBar` 类型，包含以下属性：
- Open
- High
- Low
- Close
- Volume

在QuantConnect中通过`SetHoldings`方法即可实现Long or Short，正数则为Long，负数为short
QC目前不支持同时做多和做空（对冲）

```python
# Go 100% short on SPY 
if data["SPY"].Close < self.openingBar.Low: 
	self.SetHoldings("SPY", -1)
```

**定时任务 Scheduling Events**

使用 `self.Schedule.On()`函数可以定义定时任务
```python
# 包括：执行频次（每天，13:30），对应的执行handler
self.Schedule.On(self.DateRules.EveryDay("SPY"), self.TimeRules.At(13,30), self.ClosePositions)
```

在定义任务的执行时间时需要 `DateRules` 和`TimeRules`，再加上需要执行的函数