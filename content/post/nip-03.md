+++
author = "zach zhou"
title = "详解nostr：nip-03"
date = "2023-02-21"
description = "web3"
tags = [
    "web3"
]
+++
# NIP-03
## OpenTimestamps事件认证
当存在 OTS 时，它应该包含在 `ots` 键下的现有事件主体中:
```
{
  "id": ...,
  "kind": ...,
  ...,
  ...,
  "ots": <base64-encoded OTS file data>
}
```
事件 id 必须用作 OpenTimestamp merkle 树中包含的原始hash散列。

认证可以由中继器自动提供(OTS 二进制内容附加到接收到的事件中) ，也可以由客户端自己在第一次将事件上传到中继器时提供，并由客户端用来表明事件真的“至少与(OTS 日期)一样古老”。