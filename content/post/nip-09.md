+++
author = "zach zhou"
title = "详解nostr：nip-09"
date = "2023-02-27"
description = "web3"
tags = [
    "web3"
]
+++
# NIP-09
## 删除事件

类型为5的特殊事件含义是删除，带有一个或多个带有`e`标签的数组，每一个对应到待删除的事件

每一个事件必须包含标签`e`指向待删除的事件ID

事件的`content`字段可能包含删除事件的原因：
```
{
  "kind": 5,
  "pubkey": <32-bytes hex-encoded public key of the event creator>,
  "tags": [
    ["e", "dcd59..464a2"],
    ["e", "968c5..ad7a4"],
  ],
  "content": "these posts were published by accident",
  ...other fields
}
```

中继器应该删除并停止发布任何提及到相同ID的事件，客户端应该隐藏或者对已删除的事件标识删除的状态。

中继器应该继续发布/共享删除事件，因为客户端可能已经有事件打算删除。此外，客户端应该广播删除事件到其他未接受到此事件的中继器。

## 客户端的使用

客户端可以选择完全隐藏由有效删除事件引用的任何事件，这些包括文本，私信或者其他的还没有被定义的事件类型。此外，它们可以显示事件以及一个图标或其他表明作者已经“不拥有”该事件。
`content`字段可以被替代为删除事件的内容，用户界面可以清晰的看出来这是一个删除事件的原因，并不是原始的内容。

客户端应该在隐藏或者删除任何事件之前，校验每一个在`e`标签中提及的`pubkey`是否与删除事件的`pubkey`。

客户端以他们选择的任何方式显示删除事件本身，例如，根本不显示，或者显示一个显著的通知。

## 中继器的使用

中继器可以验证删除事件只引用与删除本身具有相同 `pubkey` 的事件，但是这并不是必需的，因为中继器可能不知道所有引用的事件。

## 取消删除事件
针对删除发布删除事件没有效果。客户端和中继器没有义务支持“取消删除”功能。