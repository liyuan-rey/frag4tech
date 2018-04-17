# libev 版 shadowsocks 安装

## 安装 shadowsocks-libev

```shell
# Ubuntu 16.10 及更高版本可以直接从包源安装
sudo apt update
sudo apt install shadowsocks-libev

# Ubuntu 14.04 和 16.04 版本需要从 PPA 安装
sudo apt-get install software-properties-common -y
sudo add-apt-repository ppa:max-c-lv/shadowsocks-libev -y # 增加 launchpad.net 上原作者的 PPA 包源

sudo apt-get update
sudo apt install shadowsocks-libev
```

## 修改配置文件

```shell
# Edit the configuration file
sudo vim /etc/shadowsocks-libev/config.json
```

配置文件参考如下。

```json
{
    "server": "my_server_ip",
    "server_port": 26685,
    "local_address": "127.0.0.1",
    "local_port": 1080,
    "password": "mypassword",
    "timeout": 60,
    "method": "chacha20-ietf-poly1305",
    "fast_open": false
}
```

## 启动和停止

```shell
# 进程方式启动
sudo ss-server -c /etc/shadowsocks-libev/config.json -u

# systemd 服务方式启动
sudo systemctl start shadowsocks-libev
```

### 设置随系统启动

```shell
sudo systemctl enable shadowsocks-libev
```
