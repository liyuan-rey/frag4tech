# 在 Ubuntu 上安装 Shadowsocks Server

这个 Shadowsocks 部署指南涵盖了两种主流版本（ Python 版和 libev 版）的内容。

## 内容索引

1. [Ubuntu Server 基础环境安装](./ubuntu-server-setup.md)

1. shadowsocks 服务端的安装

    * [Python 版 shadowsocks 安装](./shadowsocks-python-setup.md)

    * [libev 版 shadowsocks 安装](./shadowsocks-libev-setup.md) -> 推荐使用

1. [shadowsocks windows 客户端安装](https://github.com/shadowsocks/shadowsocks-windows)

1. 关于混淆

    * [混淆插件 simple-obfs 安装](./shadowsocks-simpleobfs-setup.md)

    * [混淆和加速程序 kcptun 安装](./shadowsocks-kcptun-setup.md) -> 推荐使用

## 不同版本的功能比较

* Servers 功能比较

| [Features]       | [Python] | [libev] | [Go] |
| ---------------- | -------- | ------- | ---- |
| Fast Open        | Y        | Y       | N    |
| Multiple Users   | Y        | Y       | Y    |
| Management API   | Y        | Y       | N    |
| Workers          | Y        | N       | N    |
| Graceful Restart | Y        | N       | N    |
| ss-redir         | N        | Y       | N    |
| ss-tunnel        | N        | Y       | N    |
| UDP Relay        | Y        | Y       | N    |
| OTA              | Y        | Y       | Y    |

* Clients 功能比较

| [Features]         | [Windows] | [ShadowsocksX] | [Qt5] | [Android] | [iOS App Store] | [iOS Cydia] |
| ------------------ | --------- | -------------- | ----- | --------- | --------------- | ----------- |
| System Proxy       | Y         | Y              | N     | Y         | N               | Y           |
| CHNRoutes          | Y         | Y              | N     | Y         | Y               | Y           |
| PAC Configuration  | Y         | Y              | N     | N         | N               | N           |
| Profile Switching  | Y         | Y              | Y     | Y         | N               | Y           |
| QR Code Scan       | Y         | Y              | Y     | Y         | Y               | Y           |
| QR Code Generation | Y         | Y              | Y     | Y         | N               | Y           |
