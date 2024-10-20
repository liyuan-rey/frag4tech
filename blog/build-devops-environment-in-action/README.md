# 生产环境自动化部署

## 环境描述

### 基础设备

Ubuntu Server v16.04

+ VMware Workstation Pro v12 虚拟机
+ 1 CPU，1G 内存，20G 硬盘

### 软件环境

+ Docker CE 运行环境

  所有容器的运行环境，以容器方式运行着几大方面的内容：
  + 云数据库服务，如关系数据库服务、非关系数据库服务
  + 云存储服务，如对象存储服务（OSS）、文件存储服务（NAS）
  + 云应用基础支撑服务，如消息服务（kafka）、日志服务、运维监测服务（ELK）
  + 开发过程支持服务，如版本控制服务器、开发构建服务器、代码审计服务器、单元测试服务器等
  + DevOps过程支持服务，如发布服务器、部署构建服务器等
  + 应用服务器，如前端页面服务（静态网站）、后端业务服务、公用服务（工作流等）

+ 发布服务器

  使用 git server 作为发布服务器，接收开发构建后发布的静态站点、服务war包、dockerfile等发布内容。git好处是版本控制强大，为部署失败后回滚版本提供支持；同时还有githook可以触发自定义动作。

+ 部署构建服务器

  使用 jerkins 作为部署构建服务器（与开发构建服务器相区别），当发布服务器中有新内容时，触发生产环境重新部署的动作。

+ ???
+ Docker 镜像服务
+ mongodb 镜像
+ Tomcat 镜像
+ Nginx 镜像

## 环境搭建

### Docker CE 运行环境

在 Ubuntu Server v16.04 上安装 Docker CE。

> 参考文章：[Get Docker CE for Ubuntu](https://docs.docker.com/engine/installation/linux/docker-ce/ubuntu/#set-up-the-repository)

```shell
# step 1: 安装必要的一些系统工具
sudo apt-get update
sudo apt-get -y install apt-transport-https ca-certificates curl software-properties-common
# step 2: 安装GPG证书
curl -fsSL http://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo apt-key add -
# Step 3: 写入软件源信息
sudo add-apt-repository "deb [arch=amd64] http://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable"
# Step 4: 更新apt索引
sudo apt-get -y update
# Step 5: 安装Docker-CE
sudo apt-get -y install docker-ce
```

如果要安装指定版本的Docker-CE，调整第5步，指定明确版本号。请参考如下:

```shell
# Step 1: 查找Docker-CE的版本:
apt-cache madison docker-ce
#   docker-ce | 17.03.1~ce-0~ubuntu-xenial | http://mirrors.aliyun.com/docker-ce/linux/ubuntu xenial/stable amd64 Packages
#   docker-ce | 17.03.0~ce-0~ubuntu-xenial | http://mirrors.aliyun.com/docker-ce/linux/ubuntu xenial/stable amd64 Packages
# Step 2: 安装指定版本的Docker-CE: (VERSION例如上面的17.03.1~ce-0~ubuntu-xenial)
sudo apt-get -y install docker-ce=[VERSION]
```

安装后校验：

```shell
sudo docker version
```

将返回如下版本信息：

```plain
Client:
 Version:      17.09.0-ce
 API version:  1.32
 Go version:   go1.8.3
 Git commit:   afdb6d4
 Built:        Tue Sep 26 22:42:18 2017
 OS/Arch:      linux/amd64

Server:
 Version:      17.09.0-ce
 API version:  1.32 (minimum version 1.12)
 Go version:   go1.8.3
 Git commit:   afdb6d4
 Built:        Tue Sep 26 22:40:56 2017
 OS/Arch:      linux/amd64
 Experimental: false
```

我们使用Docker的第一步，应该是获取一个官方的镜像，例如mysql、wordpress。由于网络原因，我们下载一个Docker官方的镜像需要很长的时间，甚至下载失败。为此，阿里云容器镜像服务提供了官方的镜像站点，从而加速官方镜像的下载速度。

如果有阿里云 ECS 服务器，并开通了 Docker 容器镜像服务，登录容器镜像服务控制台后左侧的“镜像加速器”页面就会显示独立分配的加速地址，形如：`[系统分配前缀].mirror.aliyuncs.com`。

可以通过修改daemon配置文件 `/etc/docker/daemon.json` 来使用加速器。没有时新建该文件。

```shell
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://xxxxxxxx.mirror.aliyuncs.com"]
}
EOF
```

配置修改完后需要重启 docker。

```shell
sudo systemctl daemon-reload
sudo systemctl restart docker
```

设置 docker 随系统自启动，

```shell
sudo systemctl enable docker
# 取消自启动 sudo systemctl disable docker
```

#### Manage Docker as a non-root user

参考官方文章：[Manage Docker as a non-root user](https://docs.docker.com/engine/installation/linux/linux-postinstall/)

### git server

业务系统也是运行在容器环境中的，所以业务系统不再像以往那样发布成 java war 包，而是发布为容器镜像，镜像是以 Dockerfile 的方式来描述的。

生产环境的部署过程，主要是在部署构建服务器上基于 Dockerfile 构建产生相关业务系统镜像，再到应用服务器上基于镜像实例化容器，从而得到业务服务。

在复杂的生产环境中部署，需要对线上系统的版本做跟踪，以便在状况出现时能更快的进行定位、扩展、修复、回滚等处理。所以生产环境的 Dockerfile 需要进行版本控制，以便在需要时候进行跟踪和追溯。

生产环境的发布服务器使用 git server 来搭建，能够方便的达成上述目标。

git server 部署在内网，不面向用户，是内部使用的。对于部署人员来说只读权限就够了，对于开发人员来说需要有读和写权限以便能将业务系统的 Dockerfile 提交上来。

只读访问我们采用 GitWeb 来达成，读写访问我们采用 SSH + git-shell 免密方式达成。

这里我们不采用 `docker store` 上贡献者发布的 GitWeb 包，而是以与 Host 操作系统相同的 ubuntu 16.04 系统镜像开始从头搭建。

镜像层次如下：

+ ubuntu
+ ubuntu-nginx
+ ubuntu-nginx-gitweb

具体内容请参考：[Dockerfile](./docker-ubuntu-gitweb-nginx/Dockerfile)

```shell
sudo docker image pull ubuntu
sudo docker image pull ubuntu:latest
sudo docker image pull ubuntu:16.04
```

这三个命令效果相同，不带版本描述默认会获取最新 LTS 版本，效果和加 `latest` 标识相同，而当前最新的 LTS 版本正是 `16.04`。

ubuntu 默认镜像包含 `apt` 工具，但不包含 `nginx`、`git` 等，需要手动安装。

首先运行 ubuntu 容器，进入交互模式。

```shell
sudo docker run -it ubuntu /bin/bash
```

在容器 bash 中运行：

```shell
cp /etc/apt/source.list /etc/apt/source.list.backup
```

修改 apt 工具从 aliyun 镜像获取软件包。

```shell
sudo docker run ubuntu bash
```

### Docker 镜像服务
