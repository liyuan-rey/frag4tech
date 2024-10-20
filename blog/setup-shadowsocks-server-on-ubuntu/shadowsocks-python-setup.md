# Python 版 shadowsocks 安装

## 配置 python3 pip 环境

许多 Shadowsocks Server 部署都采用了 Python 2.x 版本，尝试以后发现它对 Python 3.x 也是支持的.

下面运行环境将采用 Ubuntu Server 16.04 自带 `Python 3.5.2`。注意 Ubuntu Server 16.04 默认没有安装 `pip` 工具，需要自己安装。

### 安装 pip

虽然很多时候我们都直接使用 `sudo apt-get install python3-pip` 来安装针对 Python 3.x 的 pip 工具，但现在 Python 官网推荐的方式是使用 `get-pip.py` 脚本来进行 pip 安装。

下面对 `get-pip.py` 脚本安装过程做介绍。

#### 使用 get-pip.py 安装 pip

可以使用 `wget https://bootstrap.pypa.io/get-pip.py` 来从官网获取 `get-pip.py` 脚本，但 wget 是单线程的，国内下载比较慢。

为加快速度，我们可以用系统浏览器或其他下载工具预先下载好 `https://bootstrap.pypa.io/get-pip.py`，然后利用 `Git Bash` 中的 `sftp` 工具上传到 Ubuntu Server 中。

```shell
sftp sam@node1    # sftp 以用户 sam 连接到远程主机 node1，下面的命令是在 `sftp>`提示符下完成的。
ls    # 列出远程主机 node1 上的远端目录下的文件，检查是否有重名文件。默认连接的远端目录是用户 sam 的主目录，也即 /home/sam
!cd /d/download    # 将本地目录设置到 get-pip.py 所在目录，这里假定 get-pip.py 被下载到 Win10 的 d:\download 目录下。
!ls    # 列出本地目录下的文件，检查  get-pip.py 是否存在。
put get-pip.py    # 将本地目录下的 get-pip.py 上传到远端目录。
bye    # 退出 sftp
```

执行下述命令安装 python3 的 pip。

```shell
sudo -H python3 get-pip.py
```

### 配置 pip 包源

使用 aliyun 镜像可以加速获取包。

```shell
cd ~
mkdir .pip
vi ~/.pip/pip.conf
```

在 pip.conf 中增加或修改以下配置：

```conf
[global]
index-url=https://mirrors.aliyun.com/pypi/simple/
[install]
trusted-host=mirrors.aliyun.com
```

## shadowsocks (python) 安装

安装加密算法包，Shadowsocks Server 推荐的加密算法 `aes-256-cfb` 需要使用它。

```shell
sudo apt-get install python-m2crypto
```

安装 Shadowsocks。

```shell
sudo -H pip3 install shadowsocks
```

创建 Shadowsocks Server 配置文件。

```shell
sudo vi /etc/shadowsocks/config.json
```

编辑其内容如下，注意替换具体 IP。参数含义可以参考 https://github.com/shadowsocks/shadowsocks/wiki/Configuration-via-Config-File

```json
{
    "server":"my_server_ip",
    "server_port":26685,
    "local_address": "127.0.0.1",
    "local_port":1080,
    "password":"mypassword",
    "timeout":300,
    "method":"aes-256-cfb",
    "fast_open":false,
    "workers":3
}
```

### 配置防火墙

检查当前防火墙规则：

```shell
sudo iptables -L -n

# 如果显示结果如下，则意味着没有启用防火墙
# Chain INPUT (policy ACCEPT)
# target       prot opt source                 destination
# Chain FORWARD (policy ACCEPT)
# target       prot opt source                 destination
# Chain OUTPUT (policy ACCEPT)
# target       prot opt source                 destination
```

如果启用了 Linux 防火墙，需要增加通过规则：

```shell
sudo iptables -I INPUT -p tcp --dport 26685 -j ACCEPT
```

注意，如果使用了 aliyun 服务器，还需要在其管理控制台增加相应安全组规则。

### 管理 Shadowsocks Server

#### 前台运行 `ssserver`

```shell
sudo ssserver -c /etc/shadowsocks/config.json
```

前台启动 ssserver 后我们无法做后续操作了，可以把它转为后台执行。

```shell
# 按 ctrl+z 暂停终端当前进程
bg    # 将暂停进程转到后台并继续执行
jobs -l    # 查看后台进程列表
fg %<jobid>    # 将 <jobid> 任务转到前台
```

终止 `ssserver` 进程可以使用下列命令。

```shell
kill <pid>    # pid 可以从 jobs -l 回显中看到，或直接使用下面的命令
ps -ef | grep /usr/local/bin/ssserver | grep -v grep | tr -s " "|cut -d " " -f2 | xargs kill
```

#### 后台运行 ssserver

以后台进程方式启动/停止/重启 Shadowsocks Server 可以使用如下命令。

```shell
ssserver -c /etc/shadowsocks/config.json -d start    # 后台运行 ssserver
ssserver -d stop    # 停止后台运行的 ssserver
ssserver -c /etc/shadowsocks/config.json -d restart    # 以后台运行方式重启 ssserver
```

```shell
less /var/log/shadowsocks.log    # 查看 ssserver 日志
```

注意： ssserver 一般不建议使用 root 权限来运行，除非有特定需要。

### 配置随系统启动

```shell
sudo vi /etc/rc.local
```

```plain
/usr/bin/python3 /usr/local/bin/ssserver -c /etc/shadowsocks/config.json -d start
```

注意检查是否有可执行权限，具体参数可以参考：https://baike.baidu.com/item/chmod

```shell
ll /etc/rc.local    # 检查
sudo chmod -c +x /etc/rc.local
```

### 杂项

#### 优化（未确认）

Optimize TCP Connection

Increase TCP link limit add following configuration to /etc/security/limits.conf file:

```conf
* soft nofile 51200
* hard nofile 51200
```

Add following configuration to /etc/sysctl.conf file:

```conf
# max open files
fs.file-max = 51200
# max read buffer
net.core.rmem_max = 67108864
# max write buffer
net.core.wmem_max = 67108864
# max processor input queue
net.core.netdev_max_backlog = 250000
# max backlog
net.core.somaxconn = 4096
# resist SYN flood attacks
net.ipv4.tcp_syncookies = 1
# reuse timewait sockets when safe
net.ipv4.tcp_tw_reuse = 0
# turn off fast time wait sockets recycling
net.ipv4.tcp_tw_recycle = 0
# short FIN timeout
net.ipv4.tcp_fin_timeout = 30
# short keepalive time
net.ipv4.tcp_keepalive_time = 1200
# outbound port range
net.ipv4.ip_local_port_range = 10000 65000
# max SYN backlog
net.ipv4.tcp_max_syn_backlog = 8192
# max timewait sockets held by system simultaneously
net.ipv4.tcp_max_tw_buckets = 5000
#
net.ipv4.tcp_fastopen = 3
#
net.ipv4.tcp_mem = 25600 51200 102400
# TCP receive buffer
net.ipv4.tcp_rmem = 4096 87380 67108864
# TCP write buffer
net.ipv4.tcp_wmem = 4096 65536 67108864
# turn on path MTU discovery
net.ipv4.tcp_mtu_probing = 1
#
net.ipv4.tcp_congestion_control = hybla
```

Reload configuration and set Shadowsocks launch params `fast_open: true`:

```shell
sudo sysctl -p
```

#### 控制脚本（未验证）

```bash
#!/bin/bash
# Author:  yeho <lj2007331 AT gmail.com>
# BLOG:  https://blog.linuxeye.com
#
# chkconfig: - 90 10
# description: Shadowsocks start/stop/status/restart script

Shadowsocks_bin=/usr/bin/ssserver
Shadowsocks_conf=/etc/shadowsocks.json

#Shadowsocks_USAGE is the message if this script is called without any options
Shadowsocks_USAGE="Usage: $0 {\e[00;32mstart\e[00m|\e[00;31mstop\e[00m|\e[00;32mstatus\e[00m|\e[00;31mrestart\e[00m}"

#SHUTDOWN_WAIT is wait time in seconds for shadowsocks proccess to stop
SHUTDOWN_WAIT=20

Shadowsocks_pid(){
    echo `ps -ef | grep $Shadowsocks_bin | grep -v grep | tr -s " "|cut -d" " -f2`
}

start() {
  pid=$(Shadowsocks_pid)
  if [ -n "$pid" ];then
    echo -e "\e[00;31mShadowsocks is already running (pid: $pid)\e[00m"
  else
    $Shadowsocks_bin -c $Shadowsocks_conf -d start
    RETVAL=$?
    if [ "$RETVAL" = "0" ]; then
        echo -e "\e[00;32mStarting Shadowsocks\e[00m"
    else
        echo -e "\e[00;32mShadowsocks start Failed\e[00m"
    fi
    status
  fi
  return 0
}

status(){
  pid=$(Shadowsocks_pid)
  if [ -n "$pid" ];then
    echo -e "\e[00;32mShadowsocks is running with pid: $pid\e[00m"
  else
    echo -e "\e[00;31mShadowsocks is not running\e[00m"
  fi
}

stop(){
  pid=$(Shadowsocks_pid)
  if [ -n "$pid" ];then
    echo -e "\e[00;31mStoping Shadowsocks\e[00m"
    $Shadowsocks_bin -c $Shadowsocks_conf -d stop
    let kwait=$SHUTDOWN_WAIT
    count=0;
    until [ `ps -p $pid | grep -c $pid` = '0' ] || [ $count -gt $kwait ]
    do
      echo -n -e "\e[00;31mwaiting for processes to exit\e[00m\n";
      sleep 1
      let count=$count+1;
    done

    if [ $count -gt $kwait ];then
      echo -n -e "\n\e[00;31mkilling processes which didn't stop after $SHUTDOWN_WAIT seconds\e[00m"
      kill -9 $pid
    fi
  else
    echo -e "\e[00;31mShadowsocks is not running\e[00m"
  fi

  return 0
}

case $1 in
    start)
          start
        ;;
        stop)  
          stop
        ;;
        restart)
          stop
          start
        ;;
        status)
      status
        ;;
        *)
      echo -e $Shadowsocks_USAGE
        ;;
esac
exit 0
```
