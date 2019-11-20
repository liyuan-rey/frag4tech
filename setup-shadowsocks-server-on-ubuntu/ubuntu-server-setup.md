# Ubuntu Server 基础环境安装

## 建立虚拟机

- 宿主机为 `Windows 10 64 位企业版`，在“启用或关闭 Windows 功能”中禁用 `Hyper-V` 特性。
- 安装 `VMware Workstation Pro v12`。
- 新建 `Ubuntu Server v16.04` 虚拟机，利用官网 ISO 文件，采用 VMware 快速安装方式，配置为：1 CPU，1G 内存，20G 硬盘，网络采用 NAT 模式。

## 配置 Ubuntu Server 基本环境

### 管理 IP 及 hostname

- 打开 Ubuntu Server 虚拟机，检查 IP 地址。

  ```shell
  ifconfig
  ```

- 为方便起见，修改 hostname 为 `node1`。

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

- 国内访问 Ubuntu 默认包源比较慢，配置 apt-get 包源使用 aliyun 镜像包源。

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

  > aliyun 官网上说若使用阿里云服务器，将包源的域名从 mirrors.aliyun.com 改为 mirrors.aliyuncs.com，不占用公网流量，但我尝试修改后反而更新速度很慢。
  > 其实 ECS Linux 服务器保持 `/etc/apt/sources.list` 内容为空，直接 `apt-get update` 就可以直接从 `mirrors.cloud.aliyuncs.com` 更新包源。

  ```shell
  sudo apt-get update    # 更新源列表，换源后必须执行才能生效
  ```

## 配置远程 SSH 连接

### 安装 OpenSSH Server

- 检查是否安装了 `openssh-server`

  ```shell
  apt list --installed | grep ssh
  ```

  如果只有 `openssh-client` 没有 `openssh-server` 就需要安装
- 安装 `openssh-server`

  ```shell
  sudo apt-get install openssh-server
  ```

- 检查 `openssh-server` 运行状态

  ```shell
  sudo service ssh status
  ```

- 如需修改 `openssh-server` 配置，如端口号、是否允许 root 远程登录等，可以编辑相关配置文件

  ```shell
  sudo vi /etc/ssh/sshd_config
  # 修改 ssh 默认监听端口（注意在 aliyun 安全组也增加对应规则）
  # Port 26022
  # 禁止 root 用户远程 ssh 登录
  # PermitRootLogin no
  # 仅允许 ssh 协议版本 2
  # Protocol 2
  ```

  修改配置后需要重启服务以使新配置生效

  ```shell
  sudo service ssh restart
  ```

### 配置 SSH 免密登录

- 在 Win10 中安装 `Git-for-Windows` 64 位，采用默认选项安装即可。这一步主要是想利用其中的 `Git Bash` 环境，如有其它熟悉的环境也可以用。下述 Win10 中的操作均是在 `Git Bash` 工具中完成。
- 生成本机 SSH 密钥对

  ```shell
  ssh-keygen -t dsa -P '' -f ~/.ssh/id_dsa    # 其中 `-t` 后面跟加密方法，推荐 `rsa`；`-P` 后面跟的是密码，这里表示密码为空，`-f` 后面为么钥存储路径。
  ```

  生成后目录结构如下，其中 `id_rsa.pub` 是公钥，另一个为私钥

  ```plain
  .ssh
    ├── id_rsa
    └── id_rsa.pub
  ```

- 将 SSH 公钥加入 Ubuntu Server

  ```shell
  ssh-copy-id -i sam@node1    # 将本机的公钥插入到远程主机 node1 的用户 sam 的 authorized_keys 文件中。这里 node1 也可以使用 IP 地址。
  ```

- 使用 SSH 连接远程主机

  ```shell
  ssh sam@node1
  ```

### SSH 远程常见情况处理

SSH 远程后，有时网络不稳定失去连接，重连后就会连接到新的 pts 伪终端，比如：

```shell
# 列出所有 pts 伪终端
ls /dev/pts
#> 0  1  2  ptmx

# 查看用户和终端使用情况
who
#> sam      pts/0        2018-03-07 09:47 (183.95.49.193)
#> sam      pts/1        2018-03-07 11:18 (183.95.49.193)
#> sam      pts/2        2018-03-07 11:26 (183.95.49.193)

w
#>  11:29:24 up 35 days, 15:46,  3 users,  load average: 0.00, 0.00, 0.00
#> USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU WHAT
#> sam      pts/0    183.95.49.193    09:47    1:41m  0.05s  0.00s sshd: sam [priv]
#> sam      pts/1    183.95.49.193    11:18    7:58   0.01s  0.01s -bash
#> sam      pts/2    183.95.49.193    11:26    1.00s  0.03s  0.00s w

# 查看当前 pts
tty
#> /dev/pts/2

# 查看其他伪终端 pts/1 上执行的进程
ps -t /dev/pts/1
#>   PID TTY          TIME CMD
#> 30274 pts/1    00:00:00 bash
#> 30282 pts/1    00:00:00 sudo
#> 30283 pts/1    00:00:00 nano

# 结束 pts/1 上执行的进程，如果结束的是伪终端 shell（此为 bash） 则伪终端就会退出
kill -9 30283 # nano
kill -9 30274 # bash
ls /dev/pts
#> 0  2  ptmx

# 切换伪终端，有人说用 sudo chvt 0，但我没尝试成功
sudo chvt 0

```
