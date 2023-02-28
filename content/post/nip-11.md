+++
author = "zach zhou"
title = "详解nostr：nip-11"
date = "2023-02-28"
description = "web3"
tags = [
    "web3"
]
+++
# NIP-11

## 中继器信息文档

中继器可以向客户端提供服务器元数据，以通知它们功能、管理联系人和各种服务器属性。这是通过 HTTP 作为 JSON 文档提供的，在与中继器的 websocket 相同的 URI 上。

当一个中继器接收到一个 HTTP 请求，其中包含了一个支持 WebSocket 升级的 URI 的 `application/nostr+json` 的 `Accept` 头，中继应该返回一个具有以下结构的文档。

```
{
  "name": <string identifying relay>,
  "description": <string with detailed information>,
  "pubkey": <administrative contact pubkey>,
  "contact": <administrative alternate contact>,
  "supported_nips": <a list of NIP numbers supported by the relay>,
  "software": <string identifying relay software URL>,
  "version": <string version identifier>
}
```

任何字段都可能被忽略，客户端必须忽略任何他们不理解的额外字段。中继器必须通过发送`Access-Control-Allow-Origin`, `Access-Control-Allow-Headers`, 和 `Access-Control-Allow-Methods` 来接受 CORS 请求

## 字段解释

### Name

中继器可以选择一个用于客户端软件的名称。这是一个字符串，应该小于30个字符，以避免客户端截断。

### Description

有关中继器的详细纯文本信息可能包含在描述字符串中。建议不要使用标记、格式或换行符进行换行，只需使用双换行符分隔段落。长度没有限制。

### Pubkey

可以使用 pubkey 列出管理联系人，其格式与 Nostr 事件(secp256k1公钥的32字节十六进制)相同。如果列出了联系人，这将为客户端提供一个推荐地址，以便向系统管理员发送加密的直接消息(见 NIP-04)。此地址的预期用途是报告滥用或非法内容，提交错误报告，或请求其他技术援助。

中继器运营商没有义务响应直接消息。

### Contact

一个替代联系人也可以列在接触字段下面，与 pubkey 的用途相同。使用 Nostr 公钥和直接消息应优先于此。该字段的内容应该是一个 URI，使用 mailto 或 https 等方案为用户提供联系方式。

### Supported NIPs

随着 Nostr 协议的发展，一些功能可能只能通过实现特定 NIP 的中继来实现。该字段是在中继中实现的 NIP 的整数标识符的数组。示例包括“ NIP-01”的1和“ NIP-09”的9。客户端的 NIP 不应该被广播，可以被客户忽略。

### Software

中继服务器实现可以在软件属性中提供。如果存在，这必须是一个网址到项目的主页。

### Version

中继服务器可以选择将其软件版本作为字符串属性发布。字符串格式由中继实现定义。建议使用版本号或提交标识符。