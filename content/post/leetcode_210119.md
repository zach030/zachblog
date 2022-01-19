+++
author = "zach zhou"
title = "DailyCode-0119"
date = "2022-01-19"
description = "2021-01-19"
tags = [
    "leetcode",
    "double_pointer",
]
+++

## [删除排序链表中的重复元素](https://leetcode-cn.com/problems/remove-duplicates-from-sorted-list-ii/)
> 存在一个按升序排列的链表，给你这个链表的头节点 head ，请你删除链表中所有存在数字重复情况的节点，只保留原始链表中 没有重复出现 的数字

链表删除元素，一定是需要记录指针的`next`和`next.next`或双指针，通过改变`next`指针来完成删除操作。在遍历链表的循环内部还需要一个for循环，来跳过重复的元素，示例如下：
> 1 --> 2 --> 3 --> 3 --> 4 --> 4 --> 5

`curr`指针指向head的前一个假头指针，判断`curr.next`(1)与`curr.next.next`(2)不相等，因此curr向后递推，当curr指向2时，发现next与next.next都为3，需要删除重复元素，因此进入内嵌循环，当curr.val!=3，通过循环后curr指向4，同理4也会跳过，最后指向5，因此最后得到链表：
> 1 --> 2 --> 5

**tips**
在操作链表时，通常需要一个虚拟的假头节点
```go
    dummy := ListNode{Next:head} // val不重要，重点在将next指针指向head
    ...
    return dummy.Next
```

### 题解
```go
/**
 * Definition for singly-linked list.
 * type ListNode struct {
 *     Val int
 *     Next *ListNode
 * }
 */
func deleteDuplicates(head *ListNode) *ListNode {
	if head == nil {
		return nil
	}
	dummy := &ListNode{Next: head}
	curr := dummy
	for curr.Next != nil && curr.Next.Next != nil {
		if curr.Next.Val == curr.Next.Next.Val {
			val := curr.Next.Val
			for curr.Next != nil && curr.Next.Val == val {
				curr.Next = curr.Next.Next
			}
			continue
		}
		curr = curr.Next
	}
	return dummy.Next
}
```

## [区间列表交集](https://leetcode-cn.com/problems/interval-list-intersections/)

> 求两个区间列表的交集，根据下列给出的图片可以很容易理解题意
输入：firstList = [[0,2],[5,10],[13,23],[24,25]], secondList = [[1,5],[8,12],[15,24],[25,26]]
输出：[[1,2],[5,5],[8,10],[15,23],[24,24],[25,25]]

![pic](https://assets.leetcode.com/uploads/2019/01/30/interval1.png)

**思考**

题目中每个区间列表都是成对不相交，因此对于A和B中的任一某子区间，都至多与一个子区间会重叠。

从左边开始遍历，当求出两者第一个交集之后，需要将尾端较小的子区间向后移，下次比较后一个区间

**代码**

```go
func intervalIntersection(firstList [][]int, secondList [][]int) [][]int {
	ret := make([][]int, 0)
	i, j := 0, 0
	for i < len(firstList) && j < len(secondList) {
		low := max(firstList[i][0], secondList[j][0])
		high := min(firstList[i][1], secondList[j][1])
		if low <= high {
			ret = append(ret, []int{low, high})
		}
		if firstList[i][1] < secondList[j][1] {
			i++
		}else{
			j++
		}
	}
	return ret
}
```


## 盛最多水的容器