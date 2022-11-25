# 尝试 Wine 中运行 .Net WPF 应用程序

## 环境

Windows 10 (1703) 64 位企业版  
VMware Workstation Pro 12  
Linux 发行版：Fedora-Workstation-Live-x86_64-25-1.3.iso  
Wine：2.8  
sudo dnf install cabextract  
winetricks：  

Mono：  
.Net SDK：4.6.1  
待测 WPF 程序：VS2017 默认 WPF 模板生成的简单应用（目标框架4.6.1）  

## 过程

1. 在 Win10 中启动 VMware 虚拟机，安装 Fedora Workstation，过程从略。然后下述步骤在 Fedora Linux 中运行。
2. 添加 Wine 官方包源
```
sudo dnf config-manager --add-repo https://dl.winehq.org/wine-builds/fedora/25/winehq.repo
```
3. 安装 Wine
```
sudo dnf install wine
```
4. 确认 Wine 安装版本
```
wine --version
```
> 注意不要使用 root 权限运行 Wine，使用 root 权限运行 wine 会导致 WINEPREFIX 等配置信息误存。
> 如果已经误用 root 权限运行了 Wine，可以这样解决：
```
sudo rm -rf ~/.wine­­
wincfg
```
5. 安装 Microsoft .NET Framework version 4.6.1 Redistributable Package 
下载地址：[https://www.microsoft.com/en-us/download/confirmation.aspx?id=49982](https://www.microsoft.com/en-us/download/confirmation.aspx?id=49982)
```
wine ./NDP461-KB3102436-x86-x64-AllOS-ENU.exe
```
