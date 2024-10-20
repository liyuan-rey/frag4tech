FROM ubuntu:16.04

# 优化 apt 包源，以 aliyun 镜像包源 优先/代替 ubuntu 官方包源 
RUN cp /etc/apt/sources.list /etc/apt/sources.list.backup

ADD ./sources.list.aliyun /etc/apt/sources.list.aliyun

# 优先方式
#RUN cat /etc/apt/sources.list.aliyun /etc/apt/sources.list.backup > /etc/apt/sources.list
# 替代方式
RUN cp -f /etc/apt/sources.list.aliyun /etc/apt/sources.list

# 更新包信息
RUN apt-get update

# 安装 git 和 gitweb
RUN apt-get install git gitweb

# 安装 lighttpd