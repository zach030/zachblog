+++
author = "zach zhou"
title = "详解nostr：nip-13"
date = "2023-03-08"
description = "web3"
tags = [
    "web3"
]
+++
# NIP-13

## 工作量证明

本nip定义了一种为nostr笔记生成和验证工作量证明的方法。工作证明(Proof Work，PoW)是将计算工作证明添加到笔记中的一种方法。这是一个承载者证明，所有中继器和客户端都可以通过少量代码进行普遍验证。这个证据可以作为阻止垃圾邮件的一种手段。

## 挖矿

如果要为NIP-01的笔记生成POW，需要加上`nonce` tag
`{"content": "It's just me mining my own business", "tags": [["nonce", "1", "20"]]}`
当进行挖矿时，nonce标记的第二个条目会被更改，并且id会被重新计算，如果id包含了足够的前导零，那么这个笔记就被挖矿成功，建议在此过程中同步更新`created_at`

nonce中的第三个对象是挖矿的难度。这使得客户端可以防止大量垃圾邮件发送者针对较低难度的POW证明，例如你要求回复帖子的内容需要目标前导零个数为30，即使回复拥有40bits的难度，你也可以拒绝。没有一个确定的目标难度，你不能拒绝它。

## 挖矿示例的帖子
```json
{
  "id": "000006d8c378af1779d2feebc7603a125d99eca0ccf1085959b307f64e5dd358",
  "pubkey": "a48380f4cfcc1ad5378294fcac36439770f9c878dd880ffa94bb74ea54a6f243",
  "created_at": 1651794653,
  "kind": 1,
  "tags": [
    [
      "nonce",
      "776797",
      "20"
    ]
  ],
  "content": "It's just me mining my own business",
  "sig": "284622fc0a3f4f1303455d5175f7ba962a3300d136085b9566801bc2e0699de0c7e31e44c81fb40ad9049173742e904713c3594a1da0fc5d2382a25c11aba977"
}
```

