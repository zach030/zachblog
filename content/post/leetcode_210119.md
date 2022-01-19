+++
author = "zach zhou"
title = "Leetcode-DailyCode"
date = "2021-10-14"
description = "2021-01-19"
tags = [
    "leetcode",
    "double_pointer",
]
+++

## [删除排序链表中的重复元素](https://leetcode-cn.com/problems/remove-duplicates-from-sorted-list-ii/)

https://assets.leetcode.com/uploads/2021/01/04/linkedlist1.jpg
> 存在一个按升序排列的链表，给你这个链表的头节点 head ，请你删除链表中所有存在数字重复情况的节点，只保留原始链表中 没有重复出现 的数字

链表删除元素，一定是需要记录指针的`next`和`next.next`或双指针，通过改变`next`指针来完成删除操作。在遍历链表的循环内部还需要一个for循环，来跳过重复的元素，示例如下：
> 1 --> 2 --> 3 --> 3 --> 4 --> 4 --> 5
