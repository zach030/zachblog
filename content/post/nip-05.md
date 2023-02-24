+++
author = "zach zhou"
title = "详解nostr：nip-05"
date = "2023-02-24"
description = "web3"
tags = [
    "web3"
]
+++
## NIP-05
### 将Nostr密钥映射到基于 DNS 的互联网标识符

在事件类型 `set_metadata`中，用户可以设置一个互联网标识符（像邮箱一样的地址）作为`nip05`的值

尽管这里指向互联网标识符的链接非常自由，但`NIP-05`设定`<local-part>`部分被限制在字符`a-z0-9-_.`中

客户端会将标识符分为`<local-part>` 和 `<domain>`两部分，并且使用这些值去构造一个GET请求，目标地址为：`https://<domain>/.well-known/nostr.json?name=<local-part>`

请求的响应值应该是带有`names`键的json对象，`names`键应该是一个从用户名到16进制字符串的映射，如果`names`中对应的公钥和`set_metadata`事件中的公钥一致，那么客户端会认为给定的公钥确实可以由其标识符引用

#### 示例

客户端接收到如下格式的事件：
```
{
  "pubkey": "b0635d6a9851d3aed0cd6c495b282167acf761729078d975fc341b22650b07b9",
  "kind": 0,
  "content": "{\"name\": \"bob\", \"nip05\": \"bob@example.com\"}"
  ...
}
```

客户端将会向`https://example.com/.well-known/nostr.json?name=bob` 发送GET请求，并且收到的响应值结果应该是：
```
{
  "names": {
    "bob": "b0635d6a9851d3aed0cd6c495b282167acf761729078d975fc341b22650b07b9"
  }
}
```

或者是带有可选的`relays`属性：
```
{
  "names": {
    "bob": "b0635d6a9851d3aed0cd6c495b282167acf761729078d975fc341b22650b07b9"
  },
  "relays": {
    "b0635d6a9851d3aed0cd6c495b282167acf761729078d975fc341b22650b07b9": [ "wss://relay.example.com", "wss://relay2.example.com" ]
  }
}
```

### 通过NIP-05标识符找到用户

客户端可以实现从互联网标识符中查找用户的公钥，流程与上面一样，但是相反: 
首先客户端获取已知的 URL，然后从那里获取用户的公钥，然后它尝试为该用户获取类型为0的事件，并检查它是否有一个匹配的“ nip05”。

### 备注

#### 客户端必须始终遵循公钥，而不是 NIP-05地址

例如，在发现`bob@bob.com`有公钥`abc...def`后，用户点击按钮进行关注，客户端必须保持对`abc...def`的追踪而不是`bob@bob.com`。如果出于任何原因，地址`https://bob.com/.well-known/nostr.json?name=bob`在未来的某个时刻所对应的公钥变为`1d2...e3f`，客户端不应该在用户的关注列表中替换公钥`abc...def`（但是应该停止展示`bob@bob.com`，因为它变成了无效的`nip05`属性）

#### 公钥必须是16进制格式

公钥必须以十六进制格式返回。NIP-19 `npub `格式的密钥只能用于在客户端 UI 中显示，而不能在此 
NIP 中显示。

#### 支持用户搜索

客户端应该允许用户去搜索他人的主页，如果客户端有一个搜索框，用户可能会输入`bob@example.com` ，并且客户端会识别并发送请求获取他的公钥返回给用户

#### 只展示域名部分作为标识符

客户端可能会将`_@domain`这样的标识符定为根标识符，并且选择只展示`<domain>`
例如，如果bob拥有`bob.com`，他可能不想要像`bob@bob.com`的标识符，显得很重复。因此Bob可以使用`_@bob.com`作为标识符，并且希望nostr客户端可以展示并同等对待为`bob.com`

#### 为什么按照 `/.well-known/nostr.json?name=<local-part>`格式

通过添加`<local-part>`作为查询的条件而不是URL路径的一部分，可以支持按需生成 JSON 的动态服务器和包含可能包含多个名称的 JSON 文件的静态服务器。

#### 允许来自Javascripts应用的访问

JavaScript Nostr 应用程序可能受到浏览器 CORS 策略的限制，这些策略阻止它们访问用户域上的`/. well-known/nostr.json`。当 CORS 阻止 JS 加载资源时，JS 程序将其视为与不存在的资源相同的网络故障，因此，纯 JS 应用程序不可能告诉用户故障是由 CORS 问题引起的

对于请求`/.well-known/nostr.json`文件网络故障的 JS Nostr 应用程序，可能会建议用户检查其服务器的 CORS 策略，例如:
```
$ curl -sI https://example.com/.well-known/nostr.json?name=bob | grep -i ^Access-Control
Access-Control-Allow-Origin: *
```

用户应确保他们`/.well-known/nostr.json` 与 HTTP 头 Access-Control-allow-Origin: * 匹配，以确保它可以由运行在现代浏览器中的 JS 应用程序进行验证。

#### 安全性约束
`/.well-known/nostr.json`必须不返回任何 HTTP 重定向
任何请求都应该忽略`/.well-known/nostr.json`的重定向