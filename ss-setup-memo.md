# ShadowSockets Server 安装记录

## 建立虚拟机

+ 宿主机为 `Windows 10 64 位企业版`，在“启用或关闭 Windows 功能”中禁用 `Hyper-V` 特性。
+ 安装 `VMware Workstation Pro v12`。
+ 新建 `Ubuntu Server v16.04` 虚拟机，利用官网 ISO 文件，采用 VMware 快速安装方式，配置为：1 CPU，1G 内存，20G 硬盘，网络采用 NAT 模式。

## 配置 Ubuntu Server 基本环境

### 管理 IP 及 hostname

+ 打开 Ubuntu Server 虚拟机，检查 IP 地址。

  ```shell
  ifconfig
  ```

+ 为方便起见，修改 hostname 为 `node1`。

  ```shell
  su    # 切换到 root 用户
  echo node1 > /etc/hostname
  reboot    # 重启 Ubuntu Server
  ```

### 添加用户

一般不推荐使用 `root` 用户做日常操作，这里在 `root` 环境中新建一个具有管理员权限的普通用户 `sam`。

```shell
useradd -d /home/sam -m -s /bin/bash sam    # 添加用户 sam，指定并创建用户主目录 /home/sam，shell 为 bash
passwd sam    # 修改密码
usermod -G adm,cdrom,sudo,dip,plugdev -a sam    # 为用户 sam 指定管理员组 adm，sudoer 组 sudo，及其它
```

退出 root 账户 `exit`，重新用 `sam` 账户登录。

### 配置 Ubuntu Server 包源

+ 国内访问 Ubuntu 默认包源比较慢，配置 apt-get 包源使用 aliyun 镜像包源。

  ```shell
  sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup    # 备份当前包源。
  sudo vi /etc/apt/sources.list    # 删除或注释原有内容，加入 aliyun 镜像包源。vi 不熟悉的话也可以使用 nano 或其它熟悉的编辑器。
  ```

  > aliyun 镜像包源主页：http://mirrors.aliyun.com。
  > 注意 Ubuntu 16.04 代号 xenial，如果使用其它版本的 Ubuntu，需要修改相应的内容。

  ```plain
  deb http://mirrors.aliyun.com/ubuntu/ xenial main multiverse restricted universe
  deb http://mirrors.aliyun.com/ubuntu/ xenial-backports main multiverse restricted universe
  deb http://mirrors.aliyun.com/ubuntu/ xenial-proposed main multiverse restricted universe
  deb http://mirrors.aliyun.com/ubuntu/ xenial-security main multiverse restricted universe
  deb http://mirrors.aliyun.com/ubuntu/ xenial-updates main multiverse restricted universe
  deb-src http://mirrors.aliyun.com/ubuntu/ xenial main multiverse restricted universe
  deb-src http://mirrors.aliyun.com/ubuntu/ xenial-backports main multiverse restricted universe
  deb-src http://mirrors.aliyun.com/ubuntu/ xenial-proposed main multiverse restricted universe
  deb-src http://mirrors.aliyun.com/ubuntu/ xenial-security main multiverse restricted universe
  deb-src http://mirrors.aliyun.com/ubuntu/ xenial-updates main multiverse restricted universe
  ```

  > aliyun官网上说若使用阿里云服务器，将包源的域名从 mirrors.aliyun.com 改为 mirrors.aliyuncs.com，不占用公网流量，但我尝试修改后反而更新速度很慢。
  > 其实 ECS Linux 服务器保持 `/etc/apt/sources.list` 内容为空，直接 `apt-get update` 就可以直接从 `mirrors.cloud.aliyuncs.com` 更新包源。

  ```shell
  sudo apt-get update    # 更新源列表，换源后必须执行才能生效
  ```

## 配置远程 SSH 连接

### 安装 OpenSSH Server

+ 检查是否安装了 `openssh-server`
  ```shell
  apt list --installed | grep ssh
  ```
  如果只有 `openssh-client` 没有 `openssh-server` 就需要安装
+ 安装 `openssh-server`
  ```shell
  sudo apt-get install openssh-server
  ```
+ 检查 `openssh-server` 运行状态
  ```shell
  sudo service ssh status
  ```
+ 如需修改 `openssh-server` 配置，如端口号、是否允许 root 远程登录等，可以编辑相关配置文件
  ```shell
  sudo vi /etc/ssh/sshd_config
  ```
  修改配置后需要重启服务以使新配置生效
  ```shell
  sudo service ssh restart
  ```

### 配置 SSH 免密登录

+ 在 Win10 中安装 `Git-for-Windows` 64位，采用默认选项安装即可。这一步主要是想利用其中的 `Git Bash` 环境，如有其它熟悉的环境也可以用。下述 Win10 中的操作均是在 `Git Bash` 工具中完成。
+ 生成本机 SSH 密钥对
  ```shell
  ssh-keygen -t dsa -P '' -f ~/.ssh/id_dsa    # 其中 `-t` 后面跟加密方法，推荐 `rsa`；`-P` 后面跟的是密码，这里表示密码为空，`-f` 后面为么钥存储路径。
  ```
  生成后目录结构如下，其中 `id_rsa.pub` 是公钥，另一个为私钥
  ```plain
  .ssh
    ├── id_rsa
    └── id_rsa.pub
  ```
+ 将 SSH 公钥加入 Ubuntu Server
  ```shell
  ssh-copy-id -i sam@node1    # 将本机的公钥插入到远程主机 node1 的用户 sam 的 authorized_keys 文件中。这里 node1 也可以使用 IP 地址。
  ```
+ 使用 SSH 连接远程主机
  ```shell
  ssh sam@node1
  ```

## 配置 python3 pip 环境

许多 ShadowSockets Server 部署都采用了 Python 2.x 版本，尝试以后发现它对 Python 3.x 也是支持的.

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

## 安装和配置 ShadowSockets Server

安装加密算法包，ShadowSockets Server 推荐的加密算法 `aes-256-cfb` 需要使用它。

```shell
sudo apt-get install python-m2crypto
```

安装 ShadowSockets。

```shell
sudo -H pip3 install shadowsocks
```

创建 ShadowSockets Server 配置文件。

```shell
sudo vi /etc/shadowsocks/config.json
```

编辑其内容如下，注意替换具体 IP。参数含义可以参考 https://github.com/shadowsocks/shadowsocks/wiki/Configuration-via-Config-File

```json
{
    "server":"my_server_ip",
    "server_port":8388,
    "local_address": "127.0.0.1",
    "local_port":1080,
    "password":"mypassword",
    "timeout":300,
    "method":"aes-256-cfb",
    "fast_open":false,
    "workers":10
}
```

### 配置防火墙

```shell
sudo iptables -I INPUT -p tcp --dport 8388 -j ACCEPT
```

### 管理 ShadowSockets Server

#### 前台运行 ssserver

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

终止 ssserver 进程可以使用下列命令。

```shell
kill <pid>    # pid 可以从 jobs -l 回显中看到，或直接使用下面的命令
ps -ef | grep /usr/local/bin/ssserver | grep -v grep | tr -s " "|cut -d " " -f2 | xargs kill
```

#### 后台运行 ssserver

以后台进程方式启动/停止/重启 ShadowSockets Server 可以使用如下命令。

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

### 优化（未确认）

Optimeze TCP Connection

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

Reload configuration and set ShadowSocks lanuch params `fast_open: true`:

```shell
sudo sysctl -p
```

### 控制脚本（）

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
