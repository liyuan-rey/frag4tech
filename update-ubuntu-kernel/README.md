# 更新 Ubuntu Linux Kernel

## 查看 Linux 内核版本

```shell
# 方法 1
cat /proc/version

# 方法 2
uname -a # 完整信息，可以看到 32/64 位架构信息
uname -sr # 简化信息
```

## 查看 Linux 版本

```shell
# 方法 1
lsb_release -a

# 方法 2
cat /etc/issue
```

## 确定升级的目标版本

这里可以查阅 Linux Kernel LTS 版本信息：https://en.wikipedia.org/wiki/Linux_kernel#Timeline

这里是官方发布的内核包地址：http://kernel.ubuntu.com/~kernel-ppa/mainline/

## 方法 1： 用 deb 包手动升级

> 注意：手动升级不能用 `sudo apt-get autoremove` 等命令卸载旧内核，但下面提供了方法手动删除旧内核包。

官方发布地址中，不同版本目录中有多个 deb 包，以 x64 架构 4.14.15 版本为例，相应文件为：

```plain
linux-headers-4.14.15-041415_4.14.15-041415.201801231530_all.deb
linux-headers-4.14.15-041415-generic_4.14.15-041415.201801231530_amd64.deb
linux-image-4.14.15-041415-generic_4.14.15-041415.201801231530_amd64.deb
```

> 注意：有些版本还会有附加文件，类似：linux-image-extra-$(VERSION.NUMBER)_amd64.deb

```shell
cd ~
mkdir kernel-4.14.15
cd kernel-4.14.15

curl -OL http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.14.15/linux-headers-4.14.15-041415_4.14.15-041415.201801231530_all.deb
curl -OL http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.14.15/linux-headers-4.14.15-041415-generic_4.14.15-041415.201801231530_amd64.deb
curl -OL http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.14.15/linux-image-4.14.15-041415-generic_4.14.15-041415.201801231530_amd64.deb

sudo dpkg -i *.deb

sudo reboot now # 重新启动使新内核生效

### 重启后

uname -sr # 确认使用了新内核

# 移除旧内核

dpkg --list | grep linux-image # 列出所有内核版本，找出旧内核包
dpkg --list | grep linux-header # 列出所有内核头文件，找出旧内核头文件

# 移除列出的所有旧内核版本
sudo apt-get purge linux-image-4.4.0-112-generic # 不止一个命令，这里以 4.4.0 旧内核举例
#...
sudo apt-get purge linux-headers-4.4.0-112 # 不止一个命令，这里以 4.4.0 旧内核头文件举例
#...

# 移除其他未使用的包
sudo apt-get autoremove

# 重建引导
sudo update-grub2
```

## 方法 2：通过 apt 升级

```shell
sudo add-apt-repository ppa:kernel-ppa/ppa
sudo apt-get update

# 列出与目标内核版本相关的包，以 4.14.15 举例
apt-cache search linux-headers-4.14.15
apt-cache search linux-image-4.14.15
apt-cache search linux-image-extra-4.14.15 # extra 包不一定会有

# 根据上面列出的包安装
sudo apt-get install linux-headers-4.14.15-041415 linux-headers-4.14.15-041415-generic linux-image-4.14.15-041415-generic

sudo reboot now # 重新启动使新内核生效

# 重启后

uname -sr # 确认使用了新内核

# 移除其他未使用的包，包括旧内核
sudo apt-get autoremove

# 重建引导
sudo update-grub2
```

## 参考文章

https://askubuntu.com/questions/119080/how-to-update-kernel-to-the-latest-mainline-version-without-any-distro-upgrade
