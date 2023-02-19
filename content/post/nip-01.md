+++
author = "zach zhou"
title = "详解nostr：nip-01"
date = "2023-02-19"
description = "web3"
tags = [
    "web3"
]
+++
# NIP-01
## 基本的协议描述

这个 NIP 定义了每个人都应该实现的基本协议。新的 NIP 可能会向这里描述的结构和流添加新的可选(或强制)字段、消息和特性。

### 事件和签名

每个用户有公私钥对，签名，公钥，编码是基于 secp256k1 圆锥曲线实现的
event对象类型的定义如下：
```json
{
  "id": <32-bytes lowercase hex-encoded sha256 of the the serialized event data>
  "pubkey": <32-bytes lowercase hex-encoded public key of the event creator>,
  "created_at": <unix timestamp in seconds>,
  "kind": <integer>,
  "tags": [
    ["e", <32-bytes hex of the id of another event>, <recommended relay URL>],
    ["p", <32-bytes hex of the key>, <recommended relay URL>],
    ... // other kinds of tags may be included later
  ],
  "content": <arbitrary string>,
  "sig": <64-bytes signature of the sha256 hash of the serialized event data, which is the same as the "id" field>
}
```
为了获取event中的id，需要对整个event进行序列化并进行sha256编码，序列化的方式是对下面的结构进行utf8格式的json序列化
```
[
  0,
  <pubkey, as a (lowercase) hex string>,
  <created_at, as a number>,
  <kind, as a number>,
  <tags, as an array of arrays of non-null strings>,
  <content, as a string>
]
```

## 客户端与中继器之间的通信

relay通过公开一个websocket供客户端连接

### 从客户端到中继器：发送事件和建立订阅关系

客户端可以发送三种类型的消息，都是按照下面样式的json格式数组：
- `["EVENT", <event JSON as defined above>]` 用来发布event
- `["REQ", <subscription_id>, <filters JSON>...]` 用来请求获得订阅的更新
- `["CLOSE", <subscription_id>]` 用于停止之前的订阅

`<subscription_id>` 是用来表示订阅的唯一字符串
`<filters>` 是一个用来决定哪些事件可以被发送进订阅的json对象，定义结构如下：
```json
{
  "ids": <a list of event ids or prefixes>,
  "authors": <a list of pubkeys or prefixes, the pubkey of an event must be one of these>,
  "kinds": <a list of a kind numbers>,
  "#e": <a list of event ids that are referenced in an "e" tag>,
  "#p": <a list of pubkeys that are referenced in a "p" tag>,
  "since": <an integer unix timestamp, events must be newer than this to pass>,
  "until": <an integer unix timestamp, events must be older than this to pass>,
  "limit": <maximum number of events to be returned in the initial query>
}
```

当relay收到`REQ`消息后需要查询本地数据库，并将满足filter要求的事件返回，将filter记录下来，所有后续的事件都将发送到这个websocket连接中，直到连接关闭。发送`CLOSE`事件时需要指定相同的`<subscription_id>` 或者使用同一个`<subscription_id>` 发送新的`REQ`事件，这样就可以覆盖之前的订阅。

包含列表的filter属性(比如 id、 kind 或 # e)是具有一个或多个值的 JSON 数组。数组的至少一个值必须与事件中的相关字段匹配，才能将条件本身视为匹配。对于 kind 等标量事件属性，来自事件的属性必须包含在筛选器列表中。对于 # e 等标记属性(其中一个事件可能有多个值) ，事件和筛选条件值必须至少有一个共同的项。

`ids` 和 `authors` 列表内是小写的十六进制字符串，可以是精确匹配的64位字符，也可以是事件值的前缀，前缀匹配是指筛选器字符串是事件值的精确字符串前缀。前缀的使用允许在查询大量值时使用更紧凑的过滤器，并且可以为客户机提供一些隐私，这些客户机可能不希望透露它们正在搜索的确切作者或事件。
 
指定的筛选器的所有条件必须匹配一个事件才能通过筛选器，也就是说，多个条件被解释为 `&&`条件。

一个`REQ`消息可能包含多个过滤器，在这种情况下，满足任何一个筛选器条件的事件都可以被返回，多个过滤器可以解释为`||`条件。

过滤器的`limit`属性仅对初始的查询生效，并可以在后续的查询中忽略。当 `limit: n` 存在时，假定初始查询中返回的事件将是最新的 `n` 个事件。返回的事件少于指定的限制是安全的，但预计中继器不会返回比请求多得多的事件，这样客户端就不会不必要地被数据淹没。


### 从中继器到客户端：发送事件和通知

从中继器向客户端可以发送两种类型的消息：
- -   `["EVENT", <subscription_id>, <event JSON as defined above>]` 用于发送客户端请求的事件
- -   `["NOTICE", <message>]`用来向客户端发送人眼可读的错误信息

NIP没有对`NOTICE`消息如何发送和处理做规定

发送`EVENT`消息时，必须携带`subscription_id`参数和对应的订阅关系绑定，也就是上面提到的客户端主动发起的`REQ`消息

## 基础的事件类型

- `0`：`set_metadata`，事件中的content内容为json结构：`{name: <username>, about: <string>, picture: <url, string>}`
- `1`：`text_note`，内容被设置为注释的文本内容(用户想说的任何内容)。非明文注释应改为使用 NIP-16中描述的类型1000-10000
- `2`：`recommend_server`：内容被设置为事件创建者想要向其关注者推荐的中继的 URL (例如，`wss://somerelay.com`)。

中继器可以选择以不同的方式处理不同的消息类型，它可以选择默认的方式来处理它不知道的类型，也可以不选择默认的方式。

## 其他备注
- 客户端不应该向每个中继打开多个 websocket。一个频道可以支持无限数量的订阅，所以客户端应该这样做。
- `tag`数组可以将标记标识符存储为每个子数组的第一个元素，随后再加上任意信息(始终作为字符串)。NIP 定义了`“p”`ーー意味着`“pubkey”`，它指向事件中提到的某个人的 pubkey。`“e”`意味着` event`，它指向这个事件正在引用、答复或以某种方式提到的事件的 id。
- 出现在`“e”`和`“p”`标签上的`“<recommended relay URL>”`项是一个可选的(可以设置为`“”`)中继器的 URL，客户端可以尝试连接这个中继器，从带标记的配置文件中获取带标记的事件或其他事件。它可能会被忽略，但它的存在是为了增加审查阻力，使中继地址在客户端之间的传播更加无缝。
