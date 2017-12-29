# 为 Windows 控制台应用程序设置默认的 CodePage

## 背景

Window 系统中的默认终端（Terminal）已经做了许多改进，使得像控制台程序（Console Application）如： `cmd.exe`、`bash.exe`、`wsl.exe`、`ubuntu.exe` 等的命令行交互和字符显示相较以往要流畅许多。

在中文 Windows 系统中，Terminal 的默认代码页是 `936 (ANSI/OEM - 简体中文 GBK)`，默认字体为 `新宋体`。`新宋体` 比较适合打印输出，在 LCD 显示屏上的效果差强人意，英文字符比较丑陋，中文字符在 12px/14px 大小时还可以，其他尺寸就不太美观了。所以，许多有情怀的开发者都希望改用更符合自己习惯的字体。

一般来说我们可以通过 Terminal 窗口的系统上下文菜单 `默认值` 或 `属性` 来分别设置默认的字体或当前程序的字体。可是，在中文 Window 系统中，该界面中并没有 `Courier New`、`Consolas`、`Ubuntu Mono`、`Source Code Pro` 之类的等宽英文字体可选，也没有 `微软雅黑` 之类的非等宽中文字体可选。

此问题在许多不同语言如如中文、日文、韩文的 Windows 系统中都存在。

## 原因

默认 Windows Terminal 在初始化时会按以下步骤执行：

1. 首先尝试读取注册表中与 Console 程序相对应的代码页设置。

  比如运行系统默认命令提示符程序 `%SystemRoot%\System32\cmd.exe` 时，将读取注册表 `HKEY_CURRENT_USER\Console\%SystemRoot%_System32_cmd.exe\CodePage` 的值（DWORD）。

  该键值将在第一次设置 `cmd.exe` 程序的窗口上下文菜单 `属性` 时创建。

1. 如果第 1 步未获取到（比如从未设置过 Console 程序的窗口 `属性` 菜单），则获取 Windows Terminal 的默认值。该默认值存放在 `HKEY_CURRENT_USER\Console\CodePage` 中。

1. 尝试加载 Console 程序的字体配置。

  以 `%SYSTEMROOT%\System32\cmd.exe` 为例，仍然是先找 `HKEY_CURRENT_USER\Console\%SystemRoot%_System32_cmd.exe\FaceName` 值（字符串）。找不到的话，就加载 Terminal 默认值 `HKEY_CURRENT_USER\Console\FaceName`。

1. 检测 `FaceName` 指定的字体是否支持 `CodePage` 指定的代码页。

1. 如果第 4 步字体不支持，则回退 `CodePage` 为系统控制面板 `区域` 设置所指定的 `非 Unicode 程序的语言` 对应的代码页。比如简体中文 Windows 中相应 `CodePage` 为 `936`。

1. 根据第 5 步的代码页查找支持的字体名称。比如 `CodePage 936` 对应于 `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Console\TrueTypeFont\936` 值，默认是 `新宋体`。

1. 根据前面确认的 CodePage 和字体初始化 Terminal。

## 处理办法 1

如果只关注英文字符字体，可以将 `HKEY_CURRENT_USER\Console\%SystemRoot%_System32_cmd.exe\CodePage` 

> 注意：
> 有些文章指出通过修改 `HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Nls\CodePage\OEMCP` 为 `65001` 来处理，这样做比较危险，因为系统初始化时有可能因为这个改动而无法启动。

