+++
author = "zach zhou"
title = "详解nostr：nip-04"
date = "2023-02-23"
description = "web3"
tags = [
    "web3"
]
+++
## NIP-04
### 加密的私信
事件类型为4的含义是“加密的私信”，它应该有以下特质：
`content`内容：用户将想要发送的内容通过将收件人的公开密钥与发件人的私人密钥相结合而生成的共享密码，基于aes-256-cbc加密算法进行加密，再经过base64编码生成的。这是由 base64编码的初始向量所附加的，就好像它是一个名为“ iv”的查询参数一样。格式如下：`"content": "<encrypted_text>?iv=<initialization_vector>"`.

`tags`必须包含一个记录可以标识消息的接收方，这样，中继器可以自然地将这一事件转发给他们，格式如下：`["p", "<pubkey, as a hex string>"]`

`tags`可能包含在之前对话中的消息，或者是我们明确回复的消息，格式如下：`["e", "<event_id>"]`
