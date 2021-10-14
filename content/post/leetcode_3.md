+++
author = "zach zhou"
title = "Leetcode Solution 3"
date = "2021-1014"
description = "无重复字符最长字串"
tags = [
    "leetcode",
    "slide-window",
]
+++

# 无重复字符最长子串
> 给定一个字符串 s ，请你找出其中不含有重复字符的 最长子串 的长度

示例

> 输入: s = "abcabcbb"
> 输出: 3 
> 解释: 因为无重复字符的最长子串是 "abc"，所以其长度为 3。

## 滑动窗口题目的模板

根据模板，可以看出滑动窗口可分为向右扩大窗口，和从左边缩小窗口
```go
    left,right :=0,0
    for right < len(str){
        // 向右扩大窗口
        window[str[right]]++
        right++
        // 从左边起缩小窗口
        for window need shrink {
            delete(window, str[left])
            left++
        }
    }
```

## 思路

使用左右指针控制子串边界，检验是否有重复元素可通过`map`来实现，关键点是当发现重复元素时，左右指针该如何移动

测试用例
> abcabcbb

1. 当 `left=0,right=2` 时，子串为 `abc` 满足无重复条件
2. `right` 再向后移动，遇到元素 `a`，通过`map`的校验可以发现出现重复元素
3. 此时 `left` 需要移动，终止条件就是`[left,right]`区间内无重复元素，而可能的重复元素就是`right`所指向的元素

因此可以写出窗口收缩的部分代码
``` go
    // rightChar: right指针所指向的元素，当前窗口内的重复元素
    // 窗口收缩代码
    for window[rightChar]>1{
        leftChar := s[left]
        window[leftChar]--
        left++
    }
```
