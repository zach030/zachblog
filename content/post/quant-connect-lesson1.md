+++
author = "zach zhou"
title = "量化交易学习记录"
date = "2023-01-14"
description = "Lesson 1 Buy And Hold / Equities"
tags = [
    "quant",
]
+++
## Lesson 1 Buy And Hold / Equities

```python
# 初始化设置总资本 sets the starting capital for your strategy
self.SetCash(25000)

# 设置回测的区间范围
self.SetStartDate(2017, 1, 1)
self.SetEndDate(2017, 10, 31)

```

获取资产：`self.AddEquity()`

这个方法有两个基本的参数：资产名称和数据解析方式
```python
self.AddEquity("SPY", Resolution.Minute)
```

这里的Resolution可以选择Minute, Second, Hour, Daily
但并不一定每个资产都有这么多的数据解析方式，需要参考文档

设置normalization mode，数据的归一化处理方式
- Raw
- Adjusted
- SplitAdjusted
- TotalReturn
```python
self.spy = self.AddEquity("SPY", Resolution.Daily,dataNormalizationMode=DataNormalizationMode.Raw)
```

protfolio：记录所有投资标的收益的dictionary
- Invested
- TotalUnrealizedProfit
- TotalPortfolioValue
- TotalMarginUsed
```python
# 查看protfolio，通过self.Portfolio[symbol]
self.Debug("Number of IBM Shares: " + str(self.Portfolio["IBM"].Invested))
```

提出一个市场单 marketOrder，后面跟的参数为asset name和shares
```python
self.MarketOrder("AAPL", 200)
```

