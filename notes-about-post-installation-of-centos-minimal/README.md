# 安装 CentOS Minimal 后的注意事项

经常需要为试验技术点创建 CentOS 环境，为了减少干扰，希望创建的 CentOS 系统环境尽量纯净、只具备基本组件，根据后续需要自主安装其他软件包。

基于这样的考虑，最合适的起点莫过于以 Minimal 模式安装的 CentOS 了。CentOS 安装过程比较简单，不再赘述。

CentOS Minimal 安装完后还有一些常见配置调整需要做，以 CentOS 7.6-1810 为例记录如下。

## 关于 VMware Tools

如果使用 WMware 虚拟机安装 CentOS，有时会困惑是否需要安装 `VMware Tools`。

从 CentOS 7 开始，系统已经自带了 `open-vm-tools`，不需要再重复安装 `VMware Tools`。如果执意安装 `VMware Tools`，它会提醒你：

>open-vm-tools are available from the OS vendor and VMware recommends using open-vm-tools.
>
>See http://kb.vmware.com/kb/2073803 for more information.

`open-vm-tools`(https://github.com/vmware/open-vm-tools) 是 `VMware Tools` 的开源实施，由一套虚拟化实用程序组成，这些程序可增强虚拟机在 VMware 环境中的功能，使管理更加有效，交互更加流畅。open-vm-tools 的主要目的是使操作系统供应商及/或社区以及虚拟设备供应商将 VMware Tools 绑定到其产品发布中。

手动安装或升级 `open-vm-tools` 可以使用命令：

```shell
yum install open-vm-tools
```

有几个注意的点：

+ 如果要实现宿主机文件夹共享，需要安装 `open-vm-tools-dkms`
+ 桌面环境还需要安装 `open-vm-tools-desktop` 以支持双向拖放文件
+ Arch Linux 用户如果需要双向拖放文件，还需要安装 `gtkmm` 和 `gtkmm3`

## 启用网卡

CentOS Minimal 安装后默认不启用网卡，无法正常访问网络，需要手动启动网卡和设置开机自启动。

```shell
ls -l /etc/sysconfig/network-scripts/ifcfg-*
#>/etc/sysconfig/network-scripts/ifcfg-ens32  /etc/sysconfig/network-scripts/ifcfg-lo
```

网卡配置文件名一般以 `ifcfg-` 开头。其中 `ifcfg-lo` 是 `127.0.0.1` 环回配置不用处理。其它是以实际设备名为后缀的，常见的有 `ifcfg-eth0` 等，我这里是 `ifcfg-ens32`。

修改对应网卡配置文件，将对应项改为：

```ini
ONBOOT=yes
NM_Controlled=no
```

然后重启网络服务

```shell
service network restart
```

也可以使用 `ifup ens32` 启动网卡。

## 安装网络工具包

 CentOS 7 Minimal 默认没有安装常用的 `ifconfig` 等网络管理程序，但提供了更强大的替代命令 `ip`。
 
 需要手动安装 `ifconfig` 可以使用下面的命令。

```shell
yum search ifconfig
#>===== Matched: ifconfig =====
#>net-tools.x86_64 : Basic networking tools
```

提示 `ifconfig` 命令在 `net-tools.x86_64` 的包里。

```shell
yum install net-tools.x86_64
```

## 配置 yum 国内包源

CentOS 7 中系统包管理器 yum 默认启用 fastestmirror 插件，当包源配置中有至少一个 `mirrorlist` 镜像列表配置时，这个插件会检测每个镜像的连接速度，按速度从高到底的顺序排序后供 yum 使用。

CentOS 默认的 `mirrorlist` 网址内容中已经包含一些国内的镜像网址了，在 fastestmirror 配合下，很多时候 yum 下载包速度不会太慢。

如果确实想替换成速度更快的指定包源，这里以阿里镜像站为例进行配置：

### CentOS-Base

备份原镜像文件，出错后可以恢复。

```shell
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
```

下载新的 CentOS-Base.repo 到 `/etc/yum.repos.d/`，注意用的是 CentOS 7 对应的包源，别弄错了

```shell
curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
```

非阿里云ECS用户会出现 Couldn't resolve host 'mirrors.cloud.aliyuncs.com' 信息，不影响使用。也可自行修改相关配置，如：

```shell
sed -i -e '/mirrors.cloud.aliyuncs.com/d' -e '/mirrors.aliyuncs.com/d' /etc/yum.repos.d/CentOS-Base.repo
```

### EPEL

备份 EPEL (如有配置其他epel源)

```shell
mv /etc/yum.repos.d/epel.repo /etc/yum.repos.d/epel.repo.backup
mv /etc/yum.repos.d/epel-testing.repo /etc/yum.repos.d/epel-testing.repo.backup
```

下载新的 EPEL 

```shell
curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
```

### docker-ce

```shell
# step 1: 安装必要的一些系统工具
sudo yum install -y yum-utils device-mapper-persistent-data lvm2
# Step 2: 添加软件源信息
sudo yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
# Step 3
sudo sed -i 's+download.docker.com+mirrors.aliyun.com/docker-ce+' /etc/yum.repos.d/docker-ce.repo
```

### PostgreSQL

```shell
mv /etc/yum.repos.d/pgdg-redhat-all.repo /etc/yum.repos.d/pgdg-redhat-all.repo.backup
yum install https://mirrors.aliyun.com/postgresql/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
sed -i 's+download.postgresql.org/pub+mirrors.aliyun.com/postgresql+' /etc/yum.repos.d/pgdg-redhat-all.repo
```

记得重建缓存。

```shell
yum clean all
yum makecache
```

## 设置网络转发和 DNS

在 CentOS Minimal 中，如果要构建 Docker 镜像或者运行容器时，当涉及到在容器中通过宿主 CentOS 访问网络，就需要设置网络转发。

比如构建 Docker 镜像，在 Dockerfile 中存在访问网络的命令，可能会遇到下述错误信息。

```plain
WARNING: IPv4 forwarding is disabled. Networking will not work.
```

并伴有类似下面的错误信息。

```plain
Failed to establish a new connection: [Errno -3] Temporary failure in name resolution
```

解决方法是修改 `/usr/lib/sysctl.d/00-system.conf` 文件，在其中添加。

```ini
net.ipv4.ip_forward=1
```

然后重启网络服务。

```shell
systemctl restart network
```

> 注意：不建议修改 `/etc/sysctl.conf` 文件，这是一个旧式文件。

此外，上面例子中的名字解析错误提示也可能是 DNS 配置错误造成的。可以检查和修改 `/etc/resolv.conf` 文件来解决，比如在文件中增加正确的 DNS 服务地址配置项。

```plain
nameserver 114.114.114.114
nameserver 8.8.8.8
```

## SSH 连接超时处理

我们常用 SSH 远程连接 Linux 服务器进行管理和维护，

### 服务端 SSH 配置修改

在 SSH 服务端上修改配置文件 `/etc/ssh/sshd_config`，注意取消配置文件中这些项的 `#` 注释。

```config
TCPKeepAlive yes
ClientAliveInterval 60
```

这样 SSH 服务端每隔 60 秒检查一次客户端连接，也即向客户端发消息，正常情况下 SSH 客户端是必然自动应答的，所以达成了即便 SSH 客户端在一段时间内没有任何指令操作，也不会断开与 SSH 服务端的连接。

注意，服务端 `ClientAliveCountMax` 配置项默认是 `3`，也即服务端连续 3 次检查客户端连接都失败后就会中断连接，可以修改这个配置达到自己想要的最大尝试次数。

接下来重新加载 SSH 服务以使配置生效。

```shell
systemctl reload sshd
```

### 客户端 SSH 配置修改

在 ssh 客户端上修改配置文件 `$HOME/.ssh/config` 添加如下配置。

```config
ServerAliveInterval 60
ServerAliveCountMax 3
```

这样 SSH 客户端每 60 秒检查一次与服务端连接，连续 3 次检查都失败才会中断连接。

客户端重新运行 SSH 建立连接时，就会使用这些新配置。

这个修改与服务端的修改配合起来可以应对网络临时中断或不稳定但 SSH 服务端/客户端程序仍在正常运行的情况。

### 使用工具

[GNU Screen](http://www.gnu.org/software/screen/)

[tmux](https://github.com/tmux/tmux)

[Byobu](http://byobu.org/)

这是几个常用的 [terminal multiplexer](https://en.wikipedia.org/wiki/Terminal_multiplexer) 可以选择。

在实验技术点的场景下显得有些重，就不多作推荐了。

## 关于文字编辑

作为 `echo ... >> ...` 的替代，我比较喜欢 `tee`。

作为 `vi` 的替代，我比较喜欢 `nano`。

可以选择安装。

```shell
yum install tee
yum install nano
```
