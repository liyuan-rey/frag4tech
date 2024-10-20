# 用 samba server 搭建文件共享服务

## 基础环境

* 系统：CentOS 7.3
* 服务：samba-server 4.4.4

## 系统账户

| 用户 | 密码     | 用户主目录 |
| ---- | -------- | ---------- |
| 培训 | 123456   | /home/培训 |
| 美工 | p@ssw0rd | /home/美工 |
| 数据 | p@ssw0rd | /home/数据 |
| 开发 | p@ssw0rd | /home/开发 |
| 文档 | p@ssw0rd | /home/文档 |
| 公共 | 123qwe   | /home/公共 |

## 共享目录

共享目录采用了一个策略：
1、各个用户只可以看见自己主目录下的内容；
2、公共的，暂存的，单独做了设置；

| 共享名       | 路径                    | 权限                          |
| ------------ | ----------------------- | ----------------------------- |
| homes        | All Home Directories    | Read/write to all known users |
| 云资源       | /home/公共/云资源       | Read only to all known users  |
| 共享资源     | /home/公共/共享资源     | Read only to all known users  |
| 虚拟机       | /home/公共/虚拟机       | Read only to all known users  |
| 软考学习资料 | /home/公共/软考学习资料 | Read only to all known users  |
| 暂存         | /home/暂存              | Read only to all known users  |

> 注意：homes是一个特殊的共享，名称不能修改，samba自动识别系统账户主目录。

在这样的策略之下，对原有的文件的安排如下：

```plain
.
├── 公共
│   ├── 共享资源
│   ├── 软考学习资料
│   ├── 虚拟机
│   └── 云资源
├── 开发
│   ├── 3.5&&uvc安装部署资源
│   ├── GAuth安装包发布
│   ├── G-link Installation Package
│   ├── GS-911installFile
│   ├── NOC安装部署资源
│   ├── SIMA安装部署资源
│   ├── TS-GISinstallFile
│   ├── v3.6安装包发布
│   ├── 安装包发布
│   └── 版本发布备份
├── 美工
│   ├── ~$1231界面问题汇总.xlsx
│   ├── Thumbs.db
│   ├── ~$按钮样式.docx
│   ├── 工具汇总
│   ├── ~$控件属性总结(唐皛).docx
│   ├── 美工资源库
│   ├── 项目工作汇总
│   ├── 项目实例汇总
│   ├── 项目图标汇总
│   ├── 资料手册
│   ├── 组内培训资料目录.txt
│   └── 组内素材
├── 培训
│   └── 新员工培训
├── 数据
│   ├── ArcGIS9.3.1
│   ├── CreateFileGDB_python
│   ├── google
│   ├── SDE_dmp
│   ├── SDE_dmp.zip
│   └── 仿Google配图模板
├── 文档
└── 暂存
    ├── 1
    ├── big data
    ├── Chengzhifeng
    ├── chenlu
    ├── chenxg
    ├── chz
    ├── Config
    ├── Deploy Noti
    ├── Desktop
    ├── ECMS
    ├── ECMS_AnalysisGauge_6393.msi
    ├── Excel-EN
    ├── gauth233(1)(1).cer
    ├── glink
    ├── gqiang
    ├── huawei
    ├── intern
    ├── java
    ├── java作业
    ├── jcj
    ├── linux
    ├── lvwei
    ├── lx
    ├── lxk
    ├── NOCGIS
    ├── ODataService-Angular-v4-master.zip
    ├── qianqi
    ├── qp
    ├── redis-latest
    ├── rjh
    ├── rp
    ├── SBC
    ├── sh
    ├── sj
    ├── smartgit-win32-setup-jre-17_0_4.zip
    ├── temp
    ├── Thumbs.db
    ├── wll
    ├── ws
    ├── xiaodm
    ├── xz
    ├── ym
    ├── zpf
    ├── 案事件系统汇报
    ├── 分析研判交接清单.txt
    ├── 新建文件夹
    └── 专利申请
```

## 配置文件

```ini
# See smb.conf.example for a more detailed config file or
# read the smb.conf manpage.
# Run 'testparm' to verify the config is correct after
# you modified it.

[global]
	workgroup = SAMBA
	security = user
	server string = Samba Server Version %v
	passdb backend = tdbsam
	log file = /root/samba-log/log.%m 
    max log size = 50 
	printing = cups
	printcap name = cups
	load printers = yes
	cups options = raw

[homes] 
    comment = Home Directories 
    read only = No 
    browseable = No 
    
[printers]
	comment = All Printers
	path = /var/tmp
	printable = Yes
	create mask = 0600
	browseable = No

[print$]
	comment = Printer Drivers
	path = /var/lib/samba/drivers
	write list = root
	create mask = 0664
	directory mask = 0775


[云资源]
	path = /home/公共/云资源
    
[共享资源]
	path = /home/公共/共享资源 

[虚拟机]
	path = /home/公共/虚拟机 

[软考学习资料]
	path = /home/公共/软考学习资料 

[暂存]
	path = /home/暂存
    read only = No 
    
```
