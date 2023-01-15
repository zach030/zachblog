+++
author = "zach zhou"
title = "量化交易 Lesson 2 Buy and Hold with a Trailing Stop"
date = "2023-01-15"
description = "Lesson 2 Buy and Hold with a Trailing Stop"
tags = [
    "quant",
]
+++
## Lesson 2 Buy and Hold with a Trailing Stop
在上一课中学会了PlaceOrder：`self.MarketOrder("AAPL", 200)`
本节中介绍一些StopOrder的方法
- stop-limit
- stop-market

StopMarketOrder方法需要指定sell的shares

```python
# Sell 300 units of IBM at or below 95% of the current close price
self.StopMarketOrder("IBM", -300, 0.95 * self.Securities["IBM"].Close)
```

每个order执行后都会触发event，需要在代码中进行监听
```python
# 监听函数
def OnOrderEvent(self, orderEvent): 
	pass
```

orderEvent中包含的属性有：Status和OrderID（唯一）
Status包括：
- Submitted：提交
- PartiallyFilled：部分成交
- Filled：成交
- Canceled：取消
- Invalid：无效

通过监听event可以得知order的执行状态，通常在执行StopMarketOrder之后一段时间，我们不会立刻进入市场，因此可以通过监听event来得知StopMarketOrder的完成时间来控制下次进入市场的时间

```python
self.stopMarketTicket = self.StopMarketOrder("SPY",-500, 0.9*self.Securities["SPY"].Close)
# stopMarketTicket 中包含orderID属性，可以在event中进行匹配

def OnOrderEvent(self, orderEvent):
	# 判断订单是否已完成
	if orderEvent.Status != OrderStatus.Filled:
		return
	
	# Printing the security fill prices.
	self.Debug(self.Securities["SPY"].Close)
	
	#2. Check if we hit our stop loss (Compare the orderEvent.Id with the stopMarketTicket.OrderId)
	#   It's important to first check if the ticket isn't null (i.e. making sure it has been submitted)
	# 判断此order是否为StopMarketOrder，如果是则修改stopMarketFillTime时间
	if self.stopMarketTicket is not None and orderEvent.OrderId==self.stopMarketTicket.OrderId :
		#3. Store datetime
		self.stopMarketFillTime=self.Time
```

在前面的StopMarketOrder中，限定的价格是固定的，但随着市场变化，这个价格也应该是变化的

通过UpdateOrderFields可以更新order

```python
updateFields = UpdateOrderFields()
# 设置order更新的stopPrice
updateFields.StopPrice = self.Securities["SPY"].Close * 0.9
# 对之前的stopMarketTicket进行更新
self.stopMarketTicket.Update(updateFields)