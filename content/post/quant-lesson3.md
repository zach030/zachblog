+++
author = "zach zhou"
title = "量化交易 Lesson 3 Setting Up Tactical Asset Allocation"
date = "2023-01-15"
description = "Lesson 3 Setting Up Tactical Asset Allocation"
tags = [
    "quant",
]
+++
## Lesson 3 Setting Up Tactical Asset Allocation

在本节课程中引入了一些专业的金融概念，首先对这些概念进行理解
1.  `Tactical Asset Allocation（TAA）` 战术性资产配置
https://wiki.mbalib.com/wiki/Tactical_Asset_Allocation

这是一种积极主动的策略，主动根据市场状态对资产配置进行动态调整
特点：
- 一般建立在分析工具的量化分析结果之上
- 资产配置主要受某资产客观测度驱使，是以价值为导向的过程

2. `Momentum Percentage Indicator` 动量百分比指标
动量可以理解为一段时间内股价涨跌变动的比率，更注重变化的速度感，常视为超买超卖的指标

在QuantConnect中定义一个动量指标：
`self.MOMP(symbol, period, resolution)`

在初始化时可以设置`self.SetWarmUp()`，原文定义的作用是： automatically pumps historical data to an indicator
可以理解为，在初始化的时候预热一段时间的数据并计算赋予指标初始值

通过 `MOMP` 方法返回的指标有一些实时更新的属性，例如：`indicator.Current.Value` 可以获取实时的指标数值

假设初始的资产包括 `SPY` 和`BND`，并且都分别定义了`MOMP`指标，现在需要根据指标对两个资产进行操作
```python
#1. If SPY has more upward momentum than BND, then we liquidate our holdings in BND and allocate 100% of our equity to SPY
if self.spyMomentum.Current.Value > self.bondMomentum.Current.Value:
	self.Liquidate("BND")
	self.SetHoldings('SPY', 1)
#2. Otherwise we liquidate our holdings in SPY and allocate 100% to BND
else:
	self.Liquidate("SPY")
	self.SetHoldings('BND', 1)