+++
author = "zach zhou"
title = "database/sql学习笔记"
date = "2023-01-08"
description = "database/sql源码分析"
tags = [
    "golang",
]
+++
golang中的database/sql包提供了非常好的底层抽象设计思想，值得我们深究学习

包的结构中，driver包内主要定义了数据库驱动的接口，而外层的sql文件是对driver接口的封装和功能集成

首先看driver文件，核心的是Driver和Conn接口
由于支持多种类型驱动，在外层的sql文件中用了全局的map来维护所有的驱动接口，并且加了读写锁，对外暴露Register函数

假设某第三方库实现了Driver接口，那么在核心的包内则应通过在init()函数调用sql包的Register函数注册当前实例到其中去
当某用户使用此第三方包时需要显式或隐式的引用此包，确保init函数被执行
```go
// Driver is the interface that must be implemented by a database

// driver.

//

// Database drivers may implement DriverContext for access

// to contexts and to parse the name only once for a pool of connections,

// instead of once per connection.

type Driver interface {

// Open returns a new connection to the database.

// The name is a string in a driver-specific format.

//

// Open may return a cached connection (one previously

// closed), but doing so is unnecessary; the sql package

// maintains a pool of idle connections for efficient re-use.

//

// The returned connection is only used by one goroutine at a

// time.

Open(name string) (Conn, error)

}

// Conn is a connection to a database. It is not used concurrently

// by multiple goroutines.

//

// Conn is assumed to be stateful.

type Conn interface {

// Prepare returns a prepared statement, bound to this connection.

Prepare(query string) (Stmt, error)

  

// Close invalidates and potentially stops any current

// prepared statements and transactions, marking this

// connection as no longer in use.

//

// Because the sql package maintains a free pool of

// connections and only calls Close when there's a surplus of

// idle connections, it shouldn't be necessary for drivers to

// do their own connection caching.

//

// Drivers must ensure all network calls made by Close

// do not block indefinitely (e.g. apply a timeout).

Close() error

  

// Begin starts and returns a new transaction.

//

// Deprecated: Drivers should implement ConnBeginTx instead (or additionally).

Begin() (Tx, error)

}
```

Driver接口只提供了一个方法，返回Conn接口
Conn接口提供三个方法：
- Prepare(query string) (Stmt, error)
- Close() error
- Begin() (Tx, error)

很直观的，我们可以想到Conn接口对应的实例就是直接与数据库进行交互的
**那么为什么不能在sql层直接提供一个Open方法返回Conn接口呢，而是要再加一层Driver接口？**

在sql.go的Open方法中，传入参数为：Open(driverName, dataSourceName string)
首先根据driverName选择到对应的驱动（Driver接口）
然后判断该接口是否实现了DriverContext，**这个接口的作用后面再看**
最后调用OpenDB，传入的参数是Connector接口

Connector接口的实现默认选项是dsnConnector
该结构包含的内容为dsn和driver接口，看起来是对driver的一个封装
实现两个方法：
- Connect(context.Context) (Conn, error)
- Driver() Driver

在OpenDB方法中，首先是初始化带cancel的ctx 和 对DB结构的赋值
然后启动一个协程：go db.connectionOpener(ctx)
因此在此方法结束后还没有创建连接

```go
func OpenDB(c driver.Connector) *DB {  
 ctx, cancel := context.WithCancel(context.Background())  
 db := &DB{  
  connector:    c,  
  openerCh:     make(chan struct{}, connectionRequestQueueSize),  
  lastPut:      make(map[*driverConn]string),  
  connRequests: make(map[uint64]chan connRequest),  
  stop:         cancel,  
 }  
  
 go db.connectionOpener(ctx)  
  
 return db  
}
```

接下来看 connectionOpener函数，作为一个初始化运行的协程，监听两个channel的消息
- ctx的Done消息，由外部cancel调用触发
- db.openerCh消息
```go
// Runs in a separate goroutine, opens new connections when requested.  
func (db *DB) connectionOpener(ctx context.Context) {  
 for {  
  select {  
  case <-ctx.Done():  
   return  
  case <-db.openerCh:  
   db.openNewConnection(ctx)  
  }  
 }  
}
```

openNewConnection方法：用来建立一个新的数据库连接
- 首先通过connector接口的Connect方法，返回一个Conn（对应的就是一个可使用的数据库连接）
- 对结构体上锁，保证变量不被修改，这里上锁的逻辑在涉及修改DB结构体字段的方法中都包含，需要注意
- 首先判断当前数据库的关闭状态，如果关闭了，且成功获得连接，则再将此连接close，并将当前的打开连接数-1（因为在调用前会乐观的先+1）
- 如果获取连接失败，产生error，则先将连接数-1，**再调用putConnDBLocked**，再调用maybeOpenNewConnections尝试打开新连接
- 若成功获得连接，则返回一个driverConn的结构，其中包含了当前db的引用、conn还有两个时间func
- 最后还要尝试调用**putConnDBLocked**
```go
// Open one new connection
func (db *DB) openNewConnection(ctx context.Context) {  
 // maybeOpenNewConnections has already executed db.numOpen++ before it sent  
 // on db.openerCh. This function must execute db.numOpen-- if the // connection fails or is closed before returning. ci, err := db.connector.Connect(ctx)  
 db.mu.Lock()  
 defer db.mu.Unlock()  
 if db.closed {  
  if err == nil {  
   ci.Close()  
  }  
  db.numOpen--  
  return  
 }  
 if err != nil {  
  db.numOpen--  
  db.putConnDBLocked(nil, err)  
  db.maybeOpenNewConnections()  
  return  
 }  
 dc := &driverConn{  
  db:         db,  
  createdAt:  nowFunc(),  
  returnedAt: nowFunc(),  
  ci:         ci,  
 }  
 if db.putConnDBLocked(dc, err) {  
  db.addDepLocked(dc, dc)  
 } else {  
  db.numOpen--  
  ci.Close()  
 }  
}
```

可以看到作为一个异步执行的函数，此方法会尝试获取conn，并通过putConnDBLocked方法将此连接记录下来

下面具体分析maybeOpenNewConnections和putConnDBLocked方法，一个是获取新的可用连接，一个是获取连接后的调用


maybeOpenNewConnections这个方法都是在被调用时都是默认外部函数已上锁
这个函数的作用不是立刻建立新的连接，而是通过向openerCh channel发消息来通知openNewConnection方法去创建连接
这个函数只是做一些当前系统连接数的判断
- 首先判断db.connRequests数目，connRequests是一个map，维护了requestID到connReq结构channel的关系
- 若系统存在最大打开数的上限，当前还能打开的连接数=最大打开数-已打开数
- 如果当前存在的待建连接请求数大于还能最大打开的连接数，则也只能打开最大连接数了，否则就能满足所有待连要求
- 通过一个for循环，向openCh发消息，注意：乐观的将已打开连接数+1（若后面打开失败，需要-1），判断db是否关闭（因为都是异步的，状态的判断很重要）
```go
// Assumes db.mu is locked.  
// If there are connRequests and the connection limit hasn't been reached,// then tell the connectionOpener to open new connections.
func (db *DB) maybeOpenNewConnections() {  
 numRequests := len(db.connRequests)  
 if db.maxOpen > 0 {  
  numCanOpen := db.maxOpen - db.numOpen  
  if numRequests > numCanOpen {  
   numRequests = numCanOpen  
  }  
 }  
 for numRequests > 0 {  
  db.numOpen++ // optimistically  
  numRequests--  
  if db.closed {  
   return  
  }  
  db.openerCh <- struct{}{}  
 }  
}
```

通过分析后得到，maybeOpenNewConnections方法只是判断应该建立多少连接，发出消息
真正建立连接的是connector接口

下面来看putConnDBLocked方法，对建立成功or失败的连接会做什么
- 首先还是判断db的关闭状态（**异步函数，时刻注意状态的变更**）
- 判断最大打开数和当前已打开数的关系
- 判断当前待建连接数connRequests（是pending状态的），从map中取出一个reqKey和req，如果error不为空，则将此driverConn标记为使用中，构造一个connReq发送到channel中
- 如果err为空，且数据没关闭，但是没有待请求连接：则怀疑是否连接已满（numCanOpen := db.maxOpen - db.numOpen）
- 开始执行清理连接的方法

```go
// Satisfy a connRequest or put the driverConn in the idle pool and return true// or return false.  
// putConnDBLocked will satisfy a connRequest if there is one, or it will// return the *driverConn to the freeConn list if err == nil and the idle// connection limit will not be exceeded.  
// If err != nil, the value of dc is ignored.  
// If err == nil, then dc must not equal nil.  
// If a connRequest was fulfilled or the *driverConn was placed in the// freeConn list, then true is returned, otherwise false is returned.
func (db *DB) putConnDBLocked(dc *driverConn, err error) bool {  
 if db.closed {  
  return false  
 }  
 if db.maxOpen > 0 && db.numOpen > db.maxOpen {  
  return false  
 }  
 if c := len(db.connRequests); c > 0 {  
  var req chan connRequest  
  var reqKey uint64  
  for reqKey, req = range db.connRequests {  
   break  
  }  
  delete(db.connRequests, reqKey) // Remove from pending requests.  
  if err == nil {  
   dc.inUse = true  
  }  
  req <- connRequest{  
   conn: dc,  
   err:  err,  
  }  
  return true  
 } else if err == nil && !db.closed {  
  if db.maxIdleConnsLocked() > len(db.freeConn) {  
   db.freeConn = append(db.freeConn, dc)  
   db.startCleanerLocked()  
   return true  
  }  
  db.maxIdleClosed++  
 }  
 return false  
}
```

这里需要再看的是将connRequest发送到channel中
  req <- connRequest{  
   conn: dc,  
   err:  err,  
  }  

创建此channel的函数是conn
下面具体分析此函数功能：
```go
// conn returns a newly-opened or cached *driverConn.

func (db *DB) conn(ctx context.Context, strategy connReuseStrategy) (*driverConn, error) {
// 上锁，判断db是否已关闭

db.mu.Lock()

if db.closed {

db.mu.Unlock()

return nil, errDBClosed

}
// 判断ctx是否已超时
// Check if the context is expired.

select {

default:

case <-ctx.Done():

db.mu.Unlock()

return nil, ctx.Err()

}

lifetime := db.maxLifetime

  
// 根据策略：如果是允许使用cache的连接且当前系统可用连接数目足够
// Prefer a free connection, if possible.

last := len(db.freeConn) - 1

if strategy == cachedOrNewConn && last >= 0 {

// Reuse the lowest idle time connection so we can close

// connections which remain idle as soon as possible.
// 取出空闲连接中的最后一个
conn := db.freeConn[last]

db.freeConn = db.freeConn[:last]
// 标记此连接使用中
conn.inUse = true
// 判断连接是否已超时,连接在初始化时会记录一个create时间
if conn.expired(lifetime) {

db.maxLifetimeClosed++

db.mu.Unlock()

conn.Close()
// 因此 这里如果拿到一个连接但是已经过期，会报错 bad connection
return nil, driver.ErrBadConn

}

db.mu.Unlock()

  

// Reset the session if required.
// 判断是否需要resetSession，这个函数干啥的后面再看
if err := conn.resetSession(ctx); errors.Is(err, driver.ErrBadConn) {

conn.Close()

return nil, err

}

  

return conn, nil

}

  

// Out of free connections or we were asked not to use one. If we're not

// allowed to open any more connections, make a request and wait.
// 走到这里，是要创建一个新的连接了，首先判断系统是否允许再创建连接
if db.maxOpen > 0 && db.numOpen >= db.maxOpen {

// Make the connRequest channel. It's buffered so that the

// connectionOpener doesn't block while waiting for the req to be read.
// 打开连接数已经到到上限，建立一个channel，用来记录pending状态的请求
req := make(chan connRequest, 1)

reqKey := db.nextRequestKeyLocked()
// 追加到connRequests map中，这里记录了key，value是一个空channel
db.connRequests[reqKey] = req
// wait标记pending的请求
db.waitCount++

db.mu.Unlock()

  

waitStart := nowFunc()

  

// Timeout the connection request with the context.
// 这里监听两个channel，一个是ctx超时，另一个是pending的请求channel
select {

case <-ctx.Done():
// 如果超时了，就把pending的reqKey从map中删掉，再试图监听一下map
// Remove the connection request and ensure no value has been sent

// on it after removing.

db.mu.Lock()

delete(db.connRequests, reqKey)

db.mu.Unlock()

  

atomic.AddInt64(&db.waitDuration, int64(time.Since(waitStart)))

  

select {

default:

case ret, ok := <-req:

if ok && ret.conn != nil {

db.putConn(ret.conn, ret.err, false)

}

}

return nil, ctx.Err()

case ret, ok := <-req:

atomic.AddInt64(&db.waitDuration, int64(time.Since(waitStart)))

  

if !ok {

return nil, errDBClosed

}

// Only check if the connection is expired if the strategy is cachedOrNewConns.

// If we require a new connection, just re-use the connection without looking

// at the expiry time. If it is expired, it will be checked when it is placed

// back into the connection pool.

// This prioritizes giving a valid connection to a client over the exact connection

// lifetime, which could expire exactly after this point anyway.

if strategy == cachedOrNewConn && ret.err == nil && ret.conn.expired(lifetime) {

db.mu.Lock()

db.maxLifetimeClosed++

db.mu.Unlock()

ret.conn.Close()

return nil, driver.ErrBadConn

}

if ret.conn == nil {

return nil, ret.err

}

  

// Reset the session if required.

if err := ret.conn.resetSession(ctx); errors.Is(err, driver.ErrBadConn) {

ret.conn.Close()

return nil, err

}

return ret.conn, ret.err

}

}

  
// 当前系统连接数还没有超过最大连接数限制
db.numOpen++ // optimistically

db.mu.Unlock()

ci, err := db.connector.Connect(ctx)

if err != nil {

db.mu.Lock()

db.numOpen-- // correct for earlier optimism

db.maybeOpenNewConnections()

db.mu.Unlock()

return nil, err

}

db.mu.Lock()

// 构造一个新的连接
dc := &driverConn{

db: db,

createdAt: nowFunc(),

returnedAt: nowFunc(),

ci: ci,

inUse: true,

}

db.addDepLocked(dc, dc)

db.mu.Unlock()

return dc, nil

}
```