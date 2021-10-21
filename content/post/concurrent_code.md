+++
author = "zach zhou"
title = "并发编程挑战--多线程交替打印"
date = "2021-10-14"
description = "多线程交替打印"
tags = [
    "concurrent",
]
+++

# 多线程交替打印

题目: [多线程面试题](https://juejin.cn/post/6844903796410155021)

## 热身

面试OceanBase的时候，出了一道算法题，两个线程交替打印1-100
使用go来解决此问题，使用两个go协程，

```go
func concurrentPrint() {
	even, odd := make(chan struct{}, 1), make(chan struct{}, 1)
	even <- struct{}{}
	count := 1
	var wg sync.WaitGroup
	go func() {
		wg.Add(1)
		for count <= 99 {
			select {
			case <-even:
				fmt.Println("t-1: ", count)
				count++
				odd <- struct{}{}
			}
		}
		wg.Done()
	}()
	go func() {
		wg.Add(1)
		for count <= 100 {
			select {
			case <-odd:
				fmt.Println("t-2: ", count)
				count++
				even <- struct{}{}
			}
		}
		wg.Done()
	}()
	wg.Wait()
	fmt.Println("done")
}
```