# 混淆和加速程序 kcptun 安装

[kcptun 主页](ttps://github.com/xtaci/kcptun)

工作示意图：

![kcptun](kcptun.png)

安装部署还可以参考：https://www.cmsky.com/kcptun/

## kcptun 服务端

在 https://github.com/xtaci/kcptun/releases 下载 Ubuntu x64 对应的 kcptun，如 `kcptun-linux-amd64-20180305.tar.gz`。

```shell
cd ~
curl -OL https://github.com/xtaci/kcptun/releases/download/v20180305/kcptun-linux-amd64-20180305.tar.gz
```

解压缩

```shell
tar -zxf kcptun-linux-amd64-20180305.tar.gz
```

解压后有 `server_linux_amd64` 和 `client_linux_amd64` 两个文件，其中 `server_linux_amd64` 是 Linux 服务端需要的。为方便使用，我们将它移动并改名。

```shell
mv server_linux_amd64 /usr/local/bin/kcptun_server
```

创建启动参数配置文件。

```shell
mkdir /etc/kcptun
touch /etc/kcptun/config.json
```

编辑内容参考如下，注意 `target` 值是本机 shadowsocks 服务开放侦听的地址及端口，`key` 是连接 kcptun 的密码。其他参数请参考 `kcptun --help`。

```json
{
    "listen": ":29900",
    "target": "127.0.0.1:8388",
    "key": "test",
    "crypt": "salsa20",
    "mode": "fast2",
    "mtu": 1350,
    "sndwnd": 1024,
    "rcvwnd": 1024,
    "datashard": 70,
    "parityshard": 30,
    "dscp": 46,
    "nocomp": false,
    "acknodelay": false,
    "nodelay": 0,
    "interval": 40,
    "resend": 0,
    "nc": 0,
    "sockbuf": 4194304,
    "keepalive": 10
}
```

> 注意：如果使用 aliyun 等云服务器，`target` 地址和端口需要在安全组配置中打开。

创建启动、停止脚本：

```shell
touch /usr/local/bin/kcptun_start.sh
touch /usr/local/bin/kcptun_stop.sh
```

脚本内容如下：

```shell
#!/bin/bash
/usr/local/bin/kcptun_server -c /etc/kcptun/config.json > /etc/kcptun/kcptun.log 2>&1 &
echo "kcptun started."
```

```shell
#!/bin/bash
echo "stopping kcptun..."
PID=`ps -ef | grep kcptun_server | grep -v grep | awk '{print $2}'`
if [ "" !=  "$PID" ]; then
  echo "killing $PID"
  kill -9 $PID
fi
echo "kcptun stopped."
```

添加到开机自启动：

```shell
chmod +x /etc/rc.local
echo "sh /usr/local/bin/kcptun_start.sh" >> /etc/rc.local
```

## kcptun 客户端

在 https://github.com/xtaci/kcptun/releases 下载 windows x64 的 kcptun 程序包，如 https://github.com/xtaci/kcptun/releases/download/v20180305/kcptun-windows-amd64-20180305.tar.gz

解压后有两个文件 `server_windows_amd64.exe` 和 `client_windows_amd64.exe`，我们只需要 `client_windows_amd64.exe`。

将 `client_windows_amd64.exe` 解压到 `%APPDATA%/kcptun/` 目录下。为方便识别，这里改名为 `kcptun_client.exe`。

在 `%APPDATA%/kcptun/config.json` 创建启动配置文件，内容如下：

```json
{
    "localaddr": ":12948",
    "remoteaddr": "10.10.10.10:29900",
    "key": "test",
    "crypt": "salsa20",
    "mode": "fast2",
    "conn": 1,
    "autoexpire": 60,
    "mtu": 1350,
    "sndwnd": 128,
    "rcvwnd": 1024,
    "datashard": 70,
    "parityshard": 30,
    "dscp": 46,
    "nocomp": false,
    "acknodelay": false,
    "nodelay": 0,
    "interval": 40,
    "resend": 0,
    "nc": 0,
    "sockbuf": 4194304,
    "keepalive": 10
}
```

注意，下列参数在服务端和客户端配置中必须保持一致：

+ key
+ crypt
+ datashard
+ parityshard
+ nocomp

`kcptun_client.exe` 是控制台程序，我们创建 VBScript 脚本来在后台执行它。

```vb
Dim RunKcptun
Set fso = CreateObject("Scripting.FileSystemObject")
Set WshShell = WScript.CreateObject("WScript.Shell")
'获取文件路径
currentPath = fso.GetFile(Wscript.ScriptFullName).ParentFolder.Path & "\"
'配置文件路径
configFile = currentPath & "config.json"
'日志文件
logFile = currentPath & "kcptun.log"
'软件运行参数
exeConfig = currentPath & "kcptun_client.exe -c " & configFile
'拼接命令行
cmdLine = "cmd /c " & exeConfig & " > " & logFile & " 2>&1"
'启动软件
WshShell.Run cmdLine, 0, False
'等待1秒
'WScript.Sleep 1000
'打印运行命令
'Wscript.echo cmdLine
Set WshShell = Nothing
Set fso = Nothing
'退出脚本
WScript.quit
```
