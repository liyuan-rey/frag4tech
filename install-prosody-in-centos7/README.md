# 在 CentOS 7 上安装 Prosody 搭建 XMPP 聊天服务器

Prosody 官网：https://prosody.im/

## 安装
Prosody 有预编译的 rpm 包，RHEL 和 CentOS 可以通过 yum 命令来安装。Prosody 的 rpm 
包需要通过 Extra Packages for Enterprise Linux (EPEL) 包源找到。

在 CentOS 上可以直接通过
```
yum install epel-release
```
来安装或更新 EPEL。

然后通过
```
sudo yum install prosody
```
来安装 Prosody。

## 配置
默认配置文件路径：`/etc/prosody/prosody.cfg.lua`

这个配置文件中已经写好了应用到全局的配置项，一般直接使用默认设置即可，如需调整全局
设置，可以在这个文件中调整相应选项。

Prosody 支持同时建立多个 IM 服务，每个服务有类似 `example.com` 的服务标识，最佳实践
是对不同服务的配置项写在独立的配置文件中，并且统一存放在 `conf.d/` 目录中，比如 
`/etc/prosody/conf.d/example.com.cfg.lua`。此目录中每个特定服务的配置文件会被 
`prosody.cfg.lua` 代码的最后一行（`conf.d/*.cfg.lua`）加载起来。

## 控制
启动 Prosody：
```
prosodyctl start
```

停止 Prosody：
```
prosodyctl stop
```

查看 Prosody 运行状态：
```
prosodyctl status
```

如果修改了任何配置，则需要重启 Prosody 以使修改生效：
```
prosodyctl stop
prosodyctl start
```
或者
```
prosodyctl restart
```

## 管理用户
添加用户：
```
prosodyctl adduser [用户名]@[域名或IP]
```

删除用户：
```
prosodyctl deluser [用户名]@[域名或IP]
```

修改密码：
```
prosodyctl passwd [用户名]@[域名或IP]
```

如果要给予某个用户管理员权限，需要修改 `conf.d/<virtualhost>.cfg.lua` 文件，将 
`[用户名]@[域名或IP]` 加入 `admins` 配置节，如：
```
admins = { "root@localhost", "admin@localhost" }
```

## 防火墙配置
在 CentOS 7 开始，已经使用 `firewalld` 替代 `iptables service` 作为防火墙（注意 
`iptables` 还是存在的）。可以使用 CentOS 7 GUI 工具 
`Applications -> Sundry -> Firewall` 配置 `firewalld` 防火墙，打开 `5222` 端口，
以便 XMPP 客户端可以连接到 Prosody。

## 开启 SSL/TLS
开启 SSL/TLS 支持首先需要生成证书，可以使用如下命令：
```
prosodyctl cert generate example.com
```
此步骤需要输入一些证书信息，解释如下：

> Country Name (2 letter code) [GB]:【在此输入两个字符的国家名。中国的为CN 】  
> State or Province Name (full name) [Berkshire]:【省份名称，如Hubei 】  
> Locality Name (eg, city) [Newbury]:【城市名称，如Wuhan】  
> Organization Name (eg, company) [My Company Ltd]:【公司名称】  
> Organizational Unit Name (eg, section) []:【部门名称】  
> Common Name (eg, your name or your server’s hostname) []:【名称，prosody需输你的虚拟主机名/IP，也会以此来命名证书文件】  
> Email Address []:【电子邮箱地址】  

将生成的证书文件 `*.key` 和 `*.crt` 拷贝到指定目录下（通常是 `/etc/prosody/certs/` 
或者 `/etc/pki/prosody/`），然后在 `conf.d/<virtualhost>.cfg.lua` 文件中配置好
相关项，如：
```lua
ssl = {
    key = “/etc/prosody/certs/example.com.key”;
    certificate = “/etc/prosody/certs/example.com.crt”;
}
```

## 启用多人聊天（MUC）功能

## 功能检查
客户端安装

