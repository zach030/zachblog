+++
author = "zach zhou"
title = "详解nostr：nip-02"
date = "2023-02-20"
description = "web3"
tags = [
    "web3"
]
+++
# NIP-02

## 联系人列表和昵称

具有 kind `3`的特殊事件(意思是“联系人列表”)定义为具有一个 `p` 标记列表，每个 `p` 标记对应于所关注的/已知的联系人简介。

每个标记条目应该包含联系人简介的键，一个可以找到来自该键的事件的中继器 URL (如果不需要，可以设置为空字符串) ，以及该联系人简介的本地昵称(或“ petname”)(也可以设置为空字符串或不提供) ，即，`[“p”，< 32-bytes hex key > ，< main relay URL > ，< petname > ]`。`content`可以是任何内容，应该被忽略。

示例：
```
{
  "kind": 3,
  "tags": [
    ["p", "91cf9..4e5ca", "wss://alicerelay.com/", "alice"],
    ["p", "14aeb..8dad4", "wss://bobrelay.com/nostr", "bob"],
    ["p", "612ae..e610f", "ws://carolrelay.com/ws", "carol"]
  ],
  "content": "",
  ...other fields
```

每个新的联系人列表在发送时会覆盖之前的，所以这里是全量的数据。中继器和客户端应该在收到联系人列表后删除过去的。

## 用途

### 联系人备份

如果用户相信一个中继将存储他们的事件足够的时间，他们可以使用这种`kind-3`事件备份他们的关注者清单和在不同的设备恢复。

### 发现联系人和拓展内容

一个客户端可能依赖于 `kind-3`事件来显示一个被关注的人的名单，根据他正在浏览的个人资料; 根据他可能关注或浏览的其他人的联系人列表来建议关注谁; 或者显示其他上下文中的数据。

### 分享中继器

一个客户端可能会发布一个完整的联系人列表，并为每个联系人提供良好的中继服务，这样其他客户端就可以根据需要更新他们的内部中继服务列表，从而增强对审查制度的抵抗力。

### 昵称方案

客户端可以使用这些联系人列表中的数据构造从其他人的联系人列表中派生出来的本地“ petname”表。这减轻了对全局人眼可读名称的需求。例如:
用户有一个内部联系人列表：
```
[
  ["p", "21df6d143fb96c2ec9d63726bf9edc71", "", "erin"]
]
```
并接收两个联系人列表，其中一个来自`21df6d143fb96c2ec9d63726bf9edc71`
```
[
  ["p", "a8bb3d884d5d90b413d9891fe4c4e46d", "", "david"]
]
```
另一个来自 `a8bb3d884d5d90b413d9891fe4c4e46d`
```
[
  ["p", "f57f54057d2a7af0efecc8b0b66f5708", "", "frank"]
]
```
当用户看到`21df6d143fb96c2ec9d63726bf9edc71`时，客户端可以显示 `erin`; 当用户看到 `a8bb3d884d5d90b413d9891fe4c4e46d`时，客户端可以显示 `david.erin`; 当用户看到 `f57f54057d2a7af0efecc8b0b66f5708`时，客户端可以显示 `frank.david.erin`。