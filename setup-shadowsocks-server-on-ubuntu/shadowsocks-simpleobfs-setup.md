# 混淆插件 simple-obfs 安装

插件地址：[https://github.com/shadowsocks/simple-obfs](https://github.com/shadowsocks/simple-obfs)

不建议使用这个混淆器，功能比较简单，性能不好。建议考虑 kcptun。

## 服务端插件

根据官方描述进行编译安装。

```shell
cd ~
sudo apt-get update

# Debian / Ubuntu
sudo apt-get install --no-install-recommends build-essential autoconf libtool libssl-dev libpcre3-dev libev-dev asciidoc xmlto automake

git clone https://github.com/shadowsocks/simple-obfs.git
cd simple-obfs
git submodule update --init --recursive
./autogen.sh
./configure && make
sudo make install
```

安装后，会产生两个程序： `/usr/local/bin/obfs-server` 和 `/usr/local/bin/obfs-local`。

修改 ss-server 的配置文件，增加插件配置节：

```json
{
    "plugin":"obfs-server",
    "plugin-opts":"obfs=http"
}
```

重启服务。

```shell
ssserver -c /etc/shadowsocks/config.json -d restart
```

## 客户端插件

Windows 下的 Shadowsocks-windows 客户端：

下载 https://github.com/shadowsocks/simple-obfs/releases 发布文件 obfs-local.zip

将压缩包中的文件（如 obfs-local.exe 等）解压到 Shadowsocks.exe 所在目录

重新运行 Shadowsocks，指定插件配置。

Android 下：

下载 https://github.com/shadowsocks/simple-obfs-android 发布文件手动安装，或者再 Google Play 安装。
