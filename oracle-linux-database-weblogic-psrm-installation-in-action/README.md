# Oracle Linux，Database，WebLogic Server，PSRM 安装实战

## 版本信息

使用笔记本电脑，创建了单台 VMware Workstation 15 Player 虚拟机进行安装部署，配置如下。

| 项   | 配置                          |
| ---- | ----------------------------- |
| CPU  | 2 core, with VT-x/EPT enabled |
| MEM  | 至少 2G，建议 4G              |
| DISK | 60G, SCSI, 精简置备           |

软件版本如下。

| 软件                           | 版本       |
| ------------------------------ | ---------- |
| Oracle Linux 7 x64             | 7.6        |
| Oracle Database 12c x64        | 12.2.0.1.0 |
| Oracle Database 12c Client x64 | 12.2.0.1.0 |
| Oracle WebLogic Server 12c     | 12.2.1.3.0 |
| OUAF                           | 4.3.0.4.0  |
| PSRM                           | 2.5.0.1.0  |

## 安装 Oracle Linux

1. 图形化界面安装比较简单，就不多说了，以下几点选项请注意：

   - 分区时注意 swap 至少 2G，可以使用 4G 内存、40G 硬盘的默认设置。后续的 Oracle 软件安装步骤中有磁盘空间剩余量检查，通不过检查就得手工重新配置 swap 和 temp 空间大小。
   - 安装时选择 “English (US)” 的语言、区域等，以及当地时区。
   - 选择了 “Server with GUI” 安装选项，右侧选择用了默认值。
   - 可以直接创建名为 `oracle` 的管理员用户，当然也可以创建其他管理员用户，待操作系统安装好后再创建普通 `oracle` 用户（更安全，但做开发用途时不太方便）。

1. 安装好系统后的一个好习惯是更新软件包到最新版本。

    用 root 运行。

    ```shell
    sudo yum -y update
    ```

    注意看 yum 的升级提示，可能需要调整 oracle linux 官方包源配置

    ```shell
    # 可选
    sudo /usr/bin/ol_yum_configure.sh
    ```

1. 修改主机名和 IP 解析记录，我用的是 `ol7gui`。

    ```shell
    # 修改主机名，将 hostname 文件内容修改为 ol7gui
    vim /etc/hostname
    # 增加 IP 解析记录，在 hosts 文末增加一行如 “192.168.126.133   ol7gui”
    vim /etc/hosts
    ```

1. `SELinux` 和 `firewalld`

    注意并不需要停用 `SELinux` 或者 `firewalld`。

### 关于关闭 SELinux 和 firewalld

用 root 用户运行。

```shell
sed -i s#SELINUX=enforcing#SELINUX=disabled#g /etc/selinux/config
setenforce 0
egrep "SELINUX=disabled" /etc/selinux/config
getenforce
systemctl stop firewalld.service
systemctl disable firewalld.service
```

### 关于 swap 空间扩容

以前装Linux服务器系统的时候，系统有2G内存，swap交换分区分了2G，现在系统内存加到了4G，建议增加交换分区。

下面把增加 4G swap 分区介绍一下（添加一个交换文件方式）：

1. 查看swap 空间大小(总计)：我的已经加完了，引用另外一台机子的查看内容。

```shell
free -m
#             total       used       free     shared    buffers     cached
#Mem:          7985        756       7228          0         98        263
#-/+ buffers/cache:        394       7590
#Swap:         8189          0       8189
```

1. 增加 4G 的交换空间

```shell
dd if=/dev/zero of=/usr/swap bs=1024 count=4096000   #/usr/swap 文件在的位置
```

如果是增加2G，则 count=2048000

```shell
# 设置交换分区
mkswap /usr/swap

# 启动交换分区
swapon /usr/swap

#此时Top命令看到交换分区增加了，此时重启后发现 swap空间又变回2G了，怎么办呢？又查了下内容发现还有一步。

# 修改/etc/fstab文件，使得新加的16G交换空间在系统重新启动后自动生效在文件最后加入：
vi /etc/fstab 增加下列内容 i进入修改模式
#    /usr/swap  swap      swap defaults 0 0

# free -m 查看swap分区大小
```

## 安装 Oracle JDK

发现系统自带的和通过 yum 安装的 OpenJDK 似乎都不完整，所以还是准备安装 Oracle JDK。

前先卸载 OpenJDK，用 root 运行。

```shell
# 查找 `installed` OpenJDK
yum list | grep openjdk
# 根据查找结果删除
yum remove *openjdk*
```

然后运行。

```shell
# 解压
tar -zxvf jdk-8u221-linux-x64.tar.gz
# 创建目标目录
mkdir /usr/java
# 移动
mv ./jdk1.8.0_221/ /usr/java
```

添加这些命令在文末。

```shell
export JAVA_HOME=/usr/java/jdk1.8.0_221
export JRE_HOME=${JAVA_HOME}/jre
export CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib:$CLASSPATH
export JAVA_PATH=${JAVA_HOME}/bin:${JRE_HOME}/bin
export PATH=$PATH:${JAVA_PATH}
```

保存并退出编辑器，然后使配置生效。

```shell
source /etc/profile
```

检查安装的 JDK。

```shell
java -version
javac
```

### 关于 OpenJDK

1. 查找 OpenJDK 目录

    ```shell
    which java
    #/usr/bin/java
    ls -lrt /usr/bin/java
    #lrwxrwxrwx. 1 root root 22 Sep  1 22:28 /usr/bin/java -> /etc/alternatives/java
    ls -lrt /etc/alternatives/java
    #lrwxrwxrwx. 1 root root 73 Sep  1 22:28 /etc/alternatives/java -> /usr/lib/jvm/java-1.8.0-openjdk-1.8.0.222.b10-0.el7_6.x86_64/jre/bin/java
    ```

    这里的 "/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.222.b10-0.el7_6.x86_64" 就是 OpenJDK 安装路径。

2. 设置 OpenJDK 环境变量

    以 root 用户编辑文件。

    ```shell
    vim /etc/profile
    ```

    添加这些命令在文件末尾。

    ```shell
    export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.222.b10-0.el7_6.x86_64
    export JRE_HOME=${JAVA_HOME}/jre
    export CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib:$CLASSPATH
    export JAVA_PATH=${JAVA_HOME}/bin:${JRE_HOME}/bin
    export PATH=$PATH:${JAVA_PATH}
    ```

    保存并退出编辑器，然后使配置生效。

    ```shell
    source /etc/profile
    ```

## Oracle Database

1. 使用 Oracle Database 12c 预配置包

    以 root 运行 Oracle Database 12c 预配置包，它可以自动安装缺失的包、自动配置 Linux 核心参数及自动创建标准安装所需要的用户及用户组。

    参考：https://docs.oracle.com/en/database/oracle/oracle-database/12.2/ladbi/installing-the-oracle-preinstallation-rpm-from-unbreakable-linux-network.html

    ```shell
    yum install oracle-database-server-12cR2-preinstall
    ```

    以 root 运行下面命令，检查核心参数是否正确创建。

    ```shell
    sysctl -p
    ```

    自动创建的 `oracle` 用户默认密码为空，需要为 `oracle` 用户设置密码，以便能进行 SSH 远程登录及操作。

    ```shell
    passwd oracle
    ```

    重启一次操作系统，以使一些配置生效。

1. 启动图形化安装程序

    使用上一步自动创建的 `oracle` 用户登录桌面。

    解压缩。

    ```shell
    unzip oracle_linuxx64_12201_database.zip
    ```

    启动图形化安装。

    ```shell
    ./database/runInstaller
    ```

    其中的选项如下：

    - "Create and configure a database"
    - "Server class"
    - "Single instance database installation" (Oracle RAC One Node Database installation 是否更具后续扩展的灵活性？)
    - "Advanced install"
    - "Enterprise Edition (7.5GB)"
    - 默认安装位置 Oracle base: "/home/oracle/app/oracle" Software location: "/home/oracle/app/oracle/product/12.2.0/dbhome_1"
    - Inventory Directory: "/home/oracle/app/oraInventory"; oraInventory Group Name: "oinstall";"General Purpose / Transaction Processing"
    - Global database name: "orcl", Oracle system identifier (SID): "orcl", Create as Container database - checked,
    - Pluggable database name: "orclpdb"
    - Enable Automatic Memory Management , Character sets "Use Unicode (AL32UTF8", no sample schemas
    - "File system", Specify database file location: "/home/oracle/app/oracle/oradata"
       提示数据文件至少需要 12,130MB 空间不够。为了避免重装，我把它重新指向 "/home/oracle/new-disk-1/app/oracle/oradata"
    - 未加入 Enterprise Management (EM) Cloud Control
    - 未启用 "Enable Recovery"
    - "Use the same password for all accounts" - sysadm
    - Operating System Groups: 全默认

    > 注意：“Create as Container database” 这种数据库类型比较复杂，根据后面的 PSRM 安装，感觉可以不要选这个选项；如果不选，“Pluggable database name” 就不再需要配置了。

    由于使用了预配置包，prerequisite 的绝大部分要求应该都已经满足。

    我安装时有两个问题：

    - 一个 soft max stack size 不够，看了一下预配置包已经修改了相关配置了，不知道为什么没起作用，问题不大所以忽略了。
    - 一个 swap 空间不足的问题，是因为我把虚拟机内存从 2G 加到 3G 但没改 swap 大小，懒得再做调整所以直接强制忽略了。

    开始正式安装过程。其中提示以 root 运行两个脚本 “/home/oracle/app/oraInventory/orainstRoot.sh” “/home/oracle/app/oracle/product/12.2.0/dbhome_1/root.sh”，不要关闭提示框，打开控制台以 root 身份按顺序运行这两个脚本。脚本运行中提示 bin directory 时使用默认的 “/usr/local/bin”，提示配置 TFA 时输入 “no”。

    要等一段时间才会安装并创建实例完成。（我的笔记本大概跑了几十分钟，中途可以切个控制台出来 `top` 指令看看有没有假死。）

1. 设置环境变量

    用 `oracle` 账户继续运行。

    ```shell
    vim /home/oracle/.bash_profile
    ```

    在文件末尾添加。

    ```shell
    export ORACLE_SID=orcl
    export ORACLE_BASE=/home/oracle/database
    export ORACLE_HOME=$ORACLE_BASE/product/12c/db_1
    export PATH=${PATH}:${ORACLE_HOME}/bin/;
    ```

    使配置生效。

    ```shell
    source /home/oracle/.bash_profile
    ```

1. 检查安装结果

    用 `oracle` 账户继续运行。

    ```shell
    sqlplus /nolog
    ```

    然后在 `Sql>` 提示符下输入。

    ```sql
    conn sys/sysadm as sysdba
    /*connected to an idle instance.*/
    STARTUP; -- 启动数据库，注意加分号
    --SHUTDOWN; -- 关闭数据库
    ```

    启动 Listener

    ```shell
    lsnrctl start
    #lsnrctl stop
    ```

### 关于先安装数据库软件，后创建数据库

如果选择了安装数据库软件而不创建数据库，那么可以在数据库软件安装完成后，单独使用 “Database Configuration Assistant (DBCA)” 工具来创建数据库。

用 `oracle` 用户登录图形界面，配置 DBCA。

```shell
dbca
```

这种创建数据库的过程我没试过，但应该与上面类似的。

注意 PSRM 需要下面两个 Oracle 数据库特性支持，安装时要关注一下：

- Oracle Spatial OR Oracle Locator
- Oracle Text

可以在 sqlplus 中运行查询确认。

```sql
SELECT COMP_NAME, STATUS FROM DBA_REGISTRY WHERE COMP_NAME IN ('Spatial','Oracle Text');

--- COMP_NAME         STATUS
---------------- --------------------------------------------
--- Oracle Text       VALID
--- Spatial           VALID
```

### 通过 EM Express 管理数据库

启动数据库及 Listener 后，用系统自带 Firefox 访问：

https://ol7gui:5500/em/

提示需要安装 Flash，到 Adobe 官网下载 rpm (8.6M，注意别下载成 1.6k 的 yum rpm 了) 到本地后运行。

```shell
yum localinstall flash-player-npapi-32.0.0.238-release.x86_64.rpm
```

重启 Firefox 浏览器后就可以正常使用 Flash 了。

EM Express 登录页面，填写用户名，密码，选中 as sysdba，留空 Container 就可以登录。

### 其他

  安装全部结束后，默认情况下没有数据库用户被启用。如果需要手动启用数据库内的用户，参考：

  ```shell
  sqlplus /nolog
  ```

  ```sql
  CONNECT SYS/sysadm as SYSDBA
  -- Enter password: sys_password
  ALTER USER <account> IDENTIFIED BY <password> ACCOUNT UNLOCK
  ```

  启用后，客户端用 sqlplus 连接时，类似如下命令：

  ```sql
  conn scott/passwd@ip:1521/orcl
  ```

## 安装 WebLogic

可以参考：https://blog.csdn.net/acmman/article/details/70093877，但因为版本不同，启动安装程序的方式不同。

下载 "Generic Installer (800 MB)" 解压缩。

运行解压后的 jar 包，启动安装程序。

```shell
java -jar fmw_12.2.1.3.0_wls.jar

解压缩要 800M /tmp 目录空间。

安装很简单，可以使用默认选项，选择只装 WebLogic 不装 Coherence，选择安装所有 features。

安装后选择自动运行配置工具：

- 创建新 domain。
- domain 安装位置：/home/oracle/new-disk-1/Oracle/Middleware/Oracle_Home/user_projects/domains/base_domain
- 使用产品模板创建 domain，选择所有模板，选择所有 checkbox
- 配置管理员账户名称、口令：weblogic/weblogic6。后面 PSRM 的 OUAF 安装时会用到，查找本文 `WLS_WEB_WLSYSUSER` 和 `WLS_WEB_WLSYSPASS`。
- Domain Mode 选择 Development。JDK 路径部分会自动检测到 JAVA_HOME 指定的 JDK。我这里用的 Oracle JDK，而不是 Oracle OpenJDK。
- 高级配置选择全部 5 项 checkbox。
- 管理服务器名称：AdminServer，监听地址：All Local Addresses，监听端口：7001。选择不启用 SSL。
- 节点管理器类型：按域的默认位置，节点管理器身份证明用户名、口令未创建新的，而是用之前的管理员账户名和口令：weblogic/weblogic6
- 受管服务器、集群配置页都用默认为空
- Coherence 集群用默认：defaultCoherenceCluster，端口 0
- 计算机配置页为空
- 部署定位、服务定位配置页用默认
- JMS 文件存储配置页用默认

然后下一步，然后创建。创建操作完成后提示管理网页路径为：http://ol7gui:7001/console

> 注意后面安装 PSRM 的 OUAF 时的 `WEB_SERVER_HOME` 路径，指的是 “/home/oracle/new-disk-1/Oracle/Middleware/Oracle_Home/wlserver”，而不是 domain 位置。

安装完成后，找到 domain 安装位置 “/home/oracle/new-disk-1/Oracle/Middleware/Oracle_Home/user_projects/domains/base_domain”，运行其中的启动脚本。

```shell
./startWebLogic.sh
```

用浏览器打开 “http://ol7gui:7001/console” 可以看到登录界面，用 `weblogic` 用户登录后可以看到管理界面。

## 安装 PSRM

### 涉及的软件清单

PSRM 的依赖软件清单如下，这些软件需要在安装 PSRM 之前就绪：

- 操作系统
  - Oracle Linux 6.5+ or 7.x (64-bit) Red Hat Enterprise Linux 6.x or 7.x (64-bit)
- 数据库服务器
  - Oracle Database Server 12.1.0.1+ Standard or Enterprise Edition
- 应用服务器
  - Oracle Java Development Kit Version 8+, 64-bit
  - Oracle Client 12.1.0.1+
  - Hibernate 4.1.0 FINAL and hibernate-search-5.5.4.Final-dist
  - Oracle WebLogic Server 12.1.3.0+ (64-bit) or Oracle WebLogic 12c (12.2.1.1+) 64-bit, as required

PSRM 软件自身需要安装的内容：

- ...

### 用户和用户组

官方文档要求创建 `cissys` 用户和 `cisusr` 用户组。

| Description                                                   | Default Value | Customer Defined Value |
| ------------------------------------------------------------- | ------------- | ---------------------- |
| Oracle Public Sector Revenue Management Administrator User ID | cissys        | oracle                 |
| Oracle Public Sector Revenue Management User Group            | cisusr        | cisusr                 |

我们搭建单台开发环境，不需要这么复杂，所以直接使用了安装 Oracle 数据库时的 `oracle` 用户。

### 关于 ksh

官方文档要求使用 `ksh`，不过我尝试使用系统默认的 `bash` 也正常完成了安装过程。

如果想要安装 ksh，下面是一些参考。

```shell
# 检查 ksh 是否已安装
ksh --version
# 如果没有安装，安装之
sudo yum install ksh
# 安装后检查 ksh 是否已经是被允许的 shell 之一，输出应该至少包含 "/bin/ksh" 这一行
cat /etc/shells | grep ksh
# 改变 <username> 用户的 shell 为 ksh
sudo chsh -s /bin/ksh <username>
# 登出用户，然后重新用 <username> 登录
#......
# 检测当前 shell 是否为 ksh，预期输出应为 "/bin/ksh"
echo $SHELL
```

### 可选安装 Oracle Client

> 注意：即便是在同一台机器上安装了 Oracle Database，就无需安装 Oracle Database Client 了。
> 后面 PSRM 安装时需要 Oracle Database 或者 Client 路径里的 Perl。
> 本文主要是以都装在同一台机器上举例。

如果不是在Oracle Database 的机器上装 WebLogic 和 PSRM，那么就需要装 Client 安装包。

执行安装程序。

```shell
unzip linuxx64_12201_client.zip
./client/runInstaller
```

需要选择安装完整版 “”，只装 Instant Client 时没有所需的 PERL 版本环境。

> 下一步选择安装路径时，因为已经安装了 Oracle Database，所以默认路径 “/home/oracle/app/oracle/product/12.2.0/dbhome_1” 提示冲突不能安装，改到 “/home/oracle/app/oracle/product/12.2.0/clienthome_1” 就可以了。

下一步直到安装成功。

然后需要设置环境变量：将下面语句加入 oracle 用户的 bash 环境

```shell
export ORACLE_CLIENT_HOME=$ORACLE_BASE/product/12.2.0/clienthome_1
```

### 设置环境变量

无论系统自带的 perl 还是 oracle database / client 安装后附带的 perl，Perl Lib 中都没有 `CGI.pm` 这个模块，
后面安装 PSRM 的 OUAF 时导致安装失败。

这里手动装一下 `CGI.pm` 模块。

```shell
export PERL_HOME=${ORACLE_HOME}/perl
#或者安装的是 Client 的话 export PERL_HOME=${ORACLE_CLIENT_HOME}/perl
export PATH=${PERL_HOME}/bin:${PATH}
export PERL5LIB=$PERL_HOME/lib:$PERL_HOME/lib/site_perl:${INSTALLDIR}/data/bin/perllib

su # 切换到 root 身份，运行后续命令

perl -e shell -MCPAN

## 然后在 cpan[1]> 提示符后输入下面命令
install CGI
```

### 安装 Hibernate

下载精确版本的 Hibernate 软件包：

- `hibernate-release-4.1.0.Final.zip`： http://sourceforge.net/projects/hibernate/files/hibernate4/
- `hibernate-search-5.5.4.Final-dist.zip`： https://sourceforge.net/projects/hibernate/files/hibernate-search/

解压文件，创建目录并复制需要的文件。

```shell
unzip hibernate-release-4.1.0.Final.zip
unzip hibernate-search-5.5.4.Final-dist.zip

mkdir -p ~/lib/hibernate/mixed-for-psrm-2.5.0.1

export HIBERNATE_JAR_DIR=~/lib/hibernate/mixed-for-psrm-2.5.0.1

cp hibernate-release-4.1.0.Final/lib/optional/ehcache/ehcache-core-2.4.3.jar $HIBERNATE_JAR_DIR
cp hibernate-release-4.1.0.Final/lib/optional/ehcache/hibernate-ehcache-4.1.0.Final.jar $HIBERNATE_JAR_DIR
cp hibernate-release-4.1.0.Final/lib/required/hibernate-commons-annotations-4.0.1.Final.jar $HIBERNATE_JAR_DIR
cp hibernate-release-4.1.0.Final/lib/required/hibernate-core-4.1.0.Final.jar $HIBERNATE_JAR_DIR
cp hibernate-release-4.1.0.Final/lib/required/hibernate-jpa-2.0-api-1.0.1.Final.jar $HIBERNATE_JAR_DIR
cp hibernate-release-4.1.0.Final/lib/required/javassist-3.15.0-GA.jar $HIBERNATE_JAR_DIR
cp hibernate-release-4.1.0.Final/lib/required/jboss-logging-3.1.0.CR2.jar $HIBERNATE_JAR_DIR
cp hibernate-release-4.1.0.Final/lib/required/jboss-transaction-api_1.1_spec-1.0.0.Final.jar $HIBERNATE_JAR_DIR

cp hibernate-search-5.5.4.Final/dist/lib/required/jboss-logging-3.3.0.Final.jar $HIBERNATE_JAR_DIR
```

接下来配置 `HIBERNATE_JAR_DIR` 环境变量。以 `oracle` 用户编辑自己的 bash 初始化文件，即 `~/.bash_profile` 文件。

```shell
vim ~/.bash_profile
```

添加这些命令在文件末尾。

```shell
export HIBERNATE_JAR_DIR=/home/oracle/lib/hibernate/mixed-for-psrm-2.5.0.1
```

保存并退出编辑器。

生效配置文件。

```shell
source ~/.bash_profile
```

### 创建数据库

启动之前安装好的 Oracle Database 数据库，并启动监听。

启动 sqlplus 连上数据库，检查 “Oracle Spatial OR Oracle Locator” “Oracle Text”，这两个特性是否已经开启。

```sql
SELECT COMP_NAME,STATUS FROM DBA_REGISTRY WHERE COMP_NAME IN ('Spatial','Oracle Text');
```

创建默认表空间 “CISTS_01”，其中路径形如 `/<db_file_location>/oradata/<DB_NAME>/cists01.dbf`，需要替换成对应数据库的实际路径。

> 注意：如果你要创建不同于 “CISTS_01” 的表空间，那一定要注意在后续安装时手动检查和修改 “Storage.xml” 文件，后面会讲到。

```sql
CREATE TABLESPACE CISTS_01 LOGGING DATAFILE '/home/oracle/new-disk-1/app/oracle/oradata/orcl/cists01.dbf'
    SIZE 1024M REUSE AUTOEXTEND ON NEXT 8192K MAXSIZE UNLIMITED EXTENT
    MANAGEMENT LOCAL UNIFORM SIZE 1M;
```

创建数据库角色。

```sql
alter session set "_ORACLE_SCRIPT"=true;

CREATE ROLE CIS_USER;
CREATE ROLE CIS_READ;
```

创建用户 `CISADM` `CISUSER` `CISOPR` `CISREAD` 并为其配置权限。

```sql
CREATE USER CISADM IDENTIFIED BY CISADM DEFAULT TABLESPACE
    CISTS_01 TEMPORARY TABLESPACE TEMP PROFILE DEFAULT;
GRANT UNLIMITED TABLESPACE TO CISADM WITH ADMIN OPTION;
GRANT SELECT ANY TABLE TO CISADM;
GRANT CREATE DATABASE LINK TO CISADM;
GRANT CONNECT TO CISADM;
GRANT RESOURCE TO CISADM;
GRANT DBA TO CISADM WITH ADMIN OPTION;
GRANT CREATE ANY SYNONYM TO CISADM;
GRANT SELECT ANY DICTIONARY TO CISADM;

CREATE USER CISUSER PROFILE DEFAULT IDENTIFIED BY CISUSER
    DEFAULT TABLESPACE CISTS_01 TEMPORARY TABLESPACE TEMP;
GRANT SELECT ANY TABLE TO CISUSER;
GRANT CIS_USER TO CISUSER;
GRANT CIS_READ TO CISUSER;
GRANT CONNECT TO CISUSER;

CREATE USER CISOPR PROFILE DEFAULT IDENTIFIED BY CISOPR DEFAULT
    TABLESPACE CISTS_01 TEMPORARY TABLESPACE TEMP;
GRANT CONNECT,RESOURCE,EXP_FULL_DATABASE TO CISOPR;

CREATE USER CISREAD IDENTIFIED BY CISREAD DEFAULT TABLESPACE
    CISTS_01 TEMPORARY TABLESPACE TEMP;
GRANT SELECT ANY TABLE TO CISREAD;
GRANT CIS_READ TO CISREAD;
GRANT CONNECT TO CISREAD;
```

### 初始化 PSRM 数据库

解压缩 PSRM 2.5.0.1 版本安装文件。

```shell
unzip Install-upgrade.zip

###
# 注意现在拿到的这个 zip 不是官方安装包，可能是某人自己合并了一下 Linux 和 Windows 安装文件。
# 包里有一些错误，比如 OUAF 数据库补丁脚本 ouafDatabasePatch.sh 未设置可执行权限等（但我们后面也没用），
# 需要做下面的修复动作，才能在 Linux 上正常执行 PSRM 数据库创建。

mv ./Install-upgrade/PSRM/V2.5.0.1.0/Install-Upgrade/OraDelUpg.INP ./Install-upgrade/PSRM/V2.5.0.1.0/Install-Upgrade/OraDelUpg.inp
```

解压后可以看到 “Install-upgrade” 文件夹，其内部含有 “FW” “PSRM” 等两个子文件夹。其中 “FW” 是 OUAF 数据库安装文件，“PSRM” 是 PSRM 数据库安装文件。

我们需要先安装 OUAF 数据库，并为其打好补丁。

OUAF 数据库安装过程中需要下列信息：

|                                                                        项 | 值                     |
| ------------------------------------------------------------------------: | :--------------------- |
|                                       Enter the database server hostname: | ol7gui                 |
|                               Enter the database port number (e.g. 1521): | 1521                   |
|                                              Enter the database name/SID: | orcl                   |
|                                             Enter your database username: | CISADM                 |
|                                  Enter your password for username CISADM: | CISADM                 |
|                                         Enter the location for Java Home: | /usr/java/jdk1.8.0_221 |
|      Enter the Oracle user with read-write privileges to Database Schema: | CISUSER                |
|       Enter the Oracle user with read-only privileges to Database Schema: | CISREAD                |
|    Enter the database role with read-write privileges to Database Schema: | CIS_USER               |
|     Enter the database role with read-only privileges to Database Schema: | CIS_READ               |
| Enter the name of the target Schema where you want to install or upgrade: | CISADM                 |

注意，具有读写权限的 `CISUSER` 用户，在后面安装 PSRM/OUAF 应用时会用到，可以用关键字 `WEB_WLSYSUSER` 搜索本文查看。

进入 FW 安装程序目录，开始创建 OUAF 数据库。

> 注意：创建开始前需要关闭其他数据库连接，比如 sqlplus 的连接。

```shell
cd ./Install-upgrade/FW/V4.3.0.4.0/Install-Upgrade

# 以交互方式运行安装程序，根据程序提示按上表输入对应值。
# TODO: 这里需要加 ${CLASSPATH}，更准确的方式是写 shell 脚本把 jarfiles 中的 jar 都加入 -cp 参数
# TODO: 不确定是否需要加 -l 1,2 参数
${JAVA_HOME}/bin/java -Xmx1500M \
    -cp ${PWD}/../jarfiles/*:${CLASSPATH} \
    com.oracle.ouaf.oem.install.OraDBI

# 还有非交互式方式如下，我比较喜欢这种
${JAVA_HOME}/bin/java -Xmx1500M \
    -cp ${PWD}/../jarfiles/*:${CLASSPATH} \
    com.oracle.ouaf.oem.install.OraDBI \
    -d ol7gui:1521/orcl,CISADM,CISADM,CISUSER,CISREAD,CIS_USER,CIS_READ,CISADM \
    -j ${JAVA_HOME} \
    -l 1,2
```

> 下面是 com.oracle.ouaf.oem.install.OraDBI 程序的使用说明，供参考。

```plain
usage: java OraDBI [-d <arg>] [-f <arg>] [-h] [-j <arg>] [-l <arg>] [-q]
OraDBI Help
   -d <arg>     db connection as:
                db_host:db_port/db_service,db_user,db_pwd,rw_user,r_user,rw_role,r_role,target_schem
                a
   -f <arg>     File to get parameters from
   -h           Help
   -j <arg>     Java home directory
   -l <arg>     NLS language
   -q           Silent mode
End of OraDBI Help
```

接下来为 OUAF 数据库打补丁。

> 官方文档中说明的利用 ouafDatabasePatch.sh 脚本运行补丁程序，但其实并不方便也不明晰，
> 所以下面没有用 ouafDatabasePatch.sh 脚本，是自己运行的 com.oracle.ouaf.database.patch.OUAFPatch 程序。

```shell
cd ./Install-upgrade/FW/V4.3.0.4.0-HotFixes/Oracle/CDXPatch

${JAVA_HOME}/bin/java \
    -cp ${PWD}/db_patch_standalone/config:${PWD}/db_patch_standalone/lib/* \
    com.oracle.ouaf.database.patch.OUAFPatch \
    -t O \
    -d CISADM,ol7gui:1521:orcl \
    -p ${PWD}/CDXPatch.ini \
    -u CISUSER,CISREAD \
    -o CIS_USER,CIS_READ \
    -r -i \
    -l ${PWD}/logcdxpatch.txt
```

> 特别注意：
> 这个 com.oracle.ouaf.database.patch.OUAFPatch 在我这运行有问题，有些交互式提示看不见，需要输入指令的时候就会卡住。
> 上述命令执行后，首先会询问 CISADM 的密码，然后要注意观察光标是否还在闪动，不闪动时就是在提示是否要做 “Generate Security”
> 安全性设置，此时输入 y 回车就好，就会继续执行完毕
> 下面是命令参数说明，供参考。参数说明好像有错误，比如 -o 的字符串顺序错了、-l 似乎应该是 lang 语言而不是日志... 所以应该以上面命令为准。

```plain
usage: java -cp OUAFPatch.jar [-c] [-d <arg>] [-h] [-i] [-l <arg>] [-n] [-o
       <arg>] [-p <arg>] [-q] [-r] [-s] [-t <arg>] [-u <arg>] [-v]
DB Patch Help
   -c           Consolidated Rollup/Service Pack
   -d <arg>     Target database connection string formatted as:
                db_user,//db_host:db_port/db_service  OR
                db_user,db_host:db_port:db_sid
   -h           Print help information
   -i           Ignore all the error generated while executing upgrade scripts.
   -l <arg>     Name of the output log file. Default name is logcdxpatch.txt
   -n           Do not Generate Security. Default always generate security (e.g
                synonyms and grants).
   -o <arg>     Optional. Names of database roles with read and read-write
                privs. Default roles are CIS_READ,CIS_USER.
   -p <arg>     Name of the file containing the list of patches. Default name is
                cdxpatch.ini.
   -q           Silent mode.
   -r           Reapply the patch.
   -s           Applying patch on Development database only.
   -t <arg>     Target database type:  O - Oracle, D - DB2 and M - MSSQL.
   -u <arg>     A comma-separated list of database users where synonyms need to
                be created
   -v           Print version information.
End of DB Patch Help

```

然后进入 PSRM 安装程序目录，开始创建 PSRM 数据库。

> 注意：创建开始前需要关闭其他数据库连接，比如 sqlplus 的连接。

```shell
cd ./Install-upgrade/PSRM/V2.5.0.1.0/Install-Upgrade

# 以交互方式运行安装程序，根据程序提示按上表输入对应值。
${JAVA_HOME}/bin/java -Xmx1500M \
    -cp ${PWD}/../jarfiles/*:${CLASSPATH} \
    com.oracle.ouaf.oem.install.OraDBI

###
## 非交互方式如下，我主要用的这个
${JAVA_HOME}/bin/java -Xmx1500M \
   -cp ${PWD}/../jarfiles/*:${CLASSPATH} \
   com.oracle.ouaf.oem.install.OraDBI \
   -d ol7gui:1521/orcl,CISADM,CISADM,CISUSER,CISREAD,CIS_USER,CIS_READ,CISADM \
   -j ${JAVA_HOME} \
   -l 1,2
```

接下来需要启用数据库 USER_LOCK 包。

```shell
sqlplus /nolog
SQL> conn sys/sysadm@ol7gui:1521/orcl as sysdba
```

```sql
@?/rdbms/admin/userlock.sql
grant execute on USER_LOCK to public;
```

### 安装 OUAF 应用

运行 OUAF 安装脚本。

> 下述根据脚本提示的配置有些多，不过好消息是，如果在安装配置过程中有中断，是可以重新运行脚本进行安装配置的。

```shell
mkdir /usr/tmp/ouaf
cp FW-V4.3.0.4.0-MultiPlatform.jar /usr/tmp/ouaf/
cd /usr/tmp/ouaf

jar -xvf FW-V4.3.0.4.0-MultiPlatform.jar

cd FW-V4.3.0.4.0-SP4/
./install.sh
```

控制台会显示第一轮安装配置清单，选项有 1， 2， 50， P， X 等。

选择 1，根据脚本提示，按下表进行配置。

|                               Menu Option | Name Used in Documentation | Customer Install Value                                                                        |
| ----------------------------------------: | -------------------------- | --------------------------------------------------------------------------------------------- |
|                            Environment ID | ENVIRONMENT_ID             | [ 每次运行都会随机生成新的，按 Enter 直接使用默认值，比如 98770140 ]                          |
|                              Server Roles | SERVER_ROLES               | batch,online                                                                                  |
|              Oracle Client Home Directory | ORACLE_CLIENT_HOME         | /home/oracle/app/oracle/product/12.2.0/clienthome_1                                           |
|                   Web Java Home Directory | JAVA_HOME                  | /usr/java/jdk1.8.0_221                                                                        |
|                   Hibernate JAR Directory | HIBERNATE_JAR_DIR          | /home/oracle/lib/hibernate/mixed-for-psrm-2.5.0.1                                             |
|                       **ONS JAR Directory | ONS_JAR_DIR                | [ 留空，参考地址：/home/oracle/app/oracle/product/12.2.0/dbhome_1/opmn/lib ]                  |
|     Web Application Server Home Directory | WEB_SERVER_HOME            | /home/oracle/new-disk-1/Oracle/Middleware/Oracle_Home/wlserver                                |
| WebLogic Server Thin-Client JAR Directory | WLTHINT3CLIENT_JAR_DIR     | [ 留空，参考地址：/home/oracle/new-disk-1/Oracle/Middleware/Oracle_Home/wlserver/server/lib ] |
|                      * ADF Home Directory | ADF_HOME                   | [ 按 Enter 直接使用默认值，可以留空 ]                                                         |
|               OIM OAM Enabled Environment | OPEN_SPML_ENABLED_ENV      | false                                                                                         |

然后选择 2，根据提示按下表配置。

|               Menu Option | Name Used in Documentation | Customer Install Value |
| ------------------------: | -------------------------- | ---------------------- |
| Import Keystore Directory | KS_IMPORT_KEYSTORE_FOLDER  | [ 留空 ]               |
|                Store Type | KS_STORETYPE               | JCEKS                  |
|                     Alias | KS_ALIAS                   | ouaf.system            |
|       Alias Key Algorithm | KS_ALIAS_KEYALG            | AES                    |
|            Alias Key Size | KS_ALIAS_KEYSIZE           | 128                    |
|                HMAC Alias | KS_HMAC_ALIAS              | ouaf.system.hmac       |
|                   Padding | KS_PADDING                 | PKCS5Padding           |
|                      Mode | KS_MODE                    | CBC                    |

选择 50 之前，先启动新的 Console 手动创建一些目录。

先创建目录 “/home/oracle/new-disk-1/ouafhome_1/log”

```shell
mkdir -p /home/oracle/new-disk-1/ouafhome_1/log
```

然后选择 50，根据提示按下表配置。

|                            Menu Option | Name Used in Documentation | Customer Install Value                 |
| -------------------------------------: | -------------------------- | -------------------------------------- |
|                Environment Mount Point | SPLDIR                     | /home/oracle/new-disk-1/ouafhome_1     |
|                   Log File Mount Point | SPLDIROUT                  | /home/oracle/new-disk-1/ouafhome_1/log |
|                       Environment Name | SPLENVIRON                 | ouaf_1 [ 这个比较重要 ]                |
|            Web Application Server Type | SPLWAS                     | WLS                                    |
| Installation Application Viewer Module | WEB_ISAPPVIEWER            | true                                   |
|    Install Demo Generation Cert Script | CERT_INSTALL_SCRIPT        | true                                   |
|          Install Sample CM Source Code | CM_INSTALL_SAMPLE          | true                                   |

选择 `P`，会看到脚本根据上面的配置信息进行了第一轮处理。

然后会显示第二轮配置清单，选项有 1， 2， 3， 4， 5， 6， 7， P， X 等。

选择 1，根据提示按下表配置。

|             Menu Option | Name Used in Documentation | Customer Install Value      |
| ----------------------: | -------------------------- | --------------------------- |
| Environment Description | DESC                       | weblogic psrm 2.5.0.1 No-01 |

选择 2，根据提示按下表配置。

|                 Menu Option | Name Used in Documentation | Customer Install Value |
| --------------------------: | -------------------------- | ---------------------- |
|        Business Server Host | BSN_WLHOST                 | ol7gui                 |
|        WebLogic Server Name | BSN_WLS_SVRNAME            | myserver               |
| Business Server Application | Name BSN_APP               | SPLService             |
|       MPL Admin Port number | MPLADMINPORT               | 6502                   |
|       MPL Automatic Startup | MPLSTART                   | false                  |

选择 3，根据提示按下表配置。

|                               Menu Option | Name Used in Documentation | Customer Install Value                                          |
| ----------------------------------------: | -------------------------- | --------------------------------------------------------------- |
|                           Web Server Host | WEB_WLHOST                 | ol7gui                                                          |
|                  Weblogic SSL Port Number | WEB_WLSSLPORT              | 6501                                                            |
|              Weblogic Console Port Number | WLS_ADMIN_PORT             | 6500                                                            |
|        Weblogic Additional Stop Arguments | ADDITIONAL_STOP_WEBLOGIC   | -                                                               |
|                          Web Context Root | WEB_CONTEXT_ROOT           | ouaf                                                            |
|                     WebLogic JNDI User ID | WEB_WLSYSUSER              | oracle [ 这里要的是 LDAP 账户，必填所以随便填了个操作系统用户 ] |
|                    WebLogic JNDI Password | WEB_WLSYSPASS              | oracle                                                          |
|             WebLogic Admin System User ID | WLS_WEB_WLSYSUSER          | weblogic [ weblogic 安装时的管理员账户 ]                        |
|            WebLogic Admin System Password | WLS_WEB_WLSYSPASS          | weblogic6                                                       |
|                      WebLogic Server Name | WEB_WLS_SVRNAME            | myserver                                                        |
|               Web Server Application Name | WEB_APP                    | SPLWeb                                                          |
|                Deploy Using Archive Files | WEB_DEPLOY_EAR             | true                                                            |
|          Deploy Application Viewer Module | WEB_DEPLOY_APPVIEWER       | true                                                            |
| Enable The Unsecured Health Check Service | WEB_ENABLE_HEALTHCHECK     | false                                                           |
|                         MDB RunAs User ID | WEB_IWS_MDB_RUNAS_USER     | [ 留空 ]                                                        |
|                            Super User Ids | WEB_IWS_SUPER_USERS        | SYSUSER ？                                                      |

选择 4，根据提示按下表配置。

|                          Menu Option | Name Used in Documentation | Customer Install Value    |
| -----------------------------------: | -------------------------- | ------------------------- |
|  Application Server Database User ID | DBUSER                     | CISADM                    |
| Application Server Database Password | DBPASS                     | CISADM                    |
|                 MPL Database User ID | MPL_DBUSER                 | CISADM                    |
|                MPL Database Password | MPL_DBPASS                 | CISADM                    |
|                 XAI Database User ID | XAI_DBUSER                 | CISADM                    |
|                XAI Database Password | XAI_DBPASS                 | CISADM                    |
|               Batch Database User ID | BATCH_DBUSER               | CISADM                    |
|              Batch Database Password | BATCH_DBPASS               | CISADM                    |
|             Web JDBC DataSource Name | JDBC_NAME                  | [ 留空 ]                  |
|                JDBC Database User ID | DBUSER_WLS                 | [ 留空 ]                  |
|               JDBC Database Password | DBPASS_WLS                 | [ 留空 ]                  |
|                        Database Name | DBNAME                     | orcl                      |
|                      Database Server | DBSERVER                   | ol7gui                    |
|                        Database Port | DBPORT                     | 1521                      |
|             ONS Server Configuration | ONSCONFIG                  | [ 留空 ]                  |
|  Database Override Connection String | DB_OVERRIDE_CONNECTION     | [ 留空 ]                  |
|             Character Based Database | CHAR_BASED_DB              | false                     |
|          Oracle Client Character Set | NLS_LANG NLS_LANG          | AMERICAN_AMERICA.AL32UTF8 |

选择 5，根据提示按下表配置。

|                      Menu Option | Name Used in Documentation   | Customer Install Value             |
| -------------------------------: | ---------------------------- | ---------------------------------- |
|                   Batch RMI Port | BATCH_RMI_PORT               | 6540                               |
| RMI Port number for JMX Business | BSN_JMX_RMI_PORT_PERFORMANCE | 6550                               |
|      RMI Port number for JMX Web | WEB_JMX_RMI_PORT_PERFORMANCE | 6570                               |
|       JMX Enablement System User | ID BSN_JMX_SYSUSER           | [ 留空 ]                           |
|   JMX Enablement System Password | BSN_JMX_SYSPASS              | [ 留空 ]                           |
|           Coherence Cluster Name | COHERENCE_CLUSTER_NAME       | [ 留空 ] ? defaultCoherenceCluster |
|        Coherence Cluster Address | COHERENCE_CLUSTER_ADDRESS    | [ 留空 ] ? 192.168.126.133         |
|           Coherence Cluster Port | COHERENCE_CLUSTER_PORT       | [ 留空 ] ? 22580                   |
|           Coherence Cluster Mode | COHERENCE_CLUSTER_MODE       | dev                                |

选择 6，根据提示按下表配置。

|                 Menu Option | Name Used in Documentation | Customer Install Value |
| --------------------------: | -------------------------- | ---------------------- |
|   Certificate Keystore Type | CERT_KS                    | DEMO                   |
|      Identify Keystore File | CERT_IDENT_KS_FILE         | [ 留空 ]               |
| Identify Keystore File Type | CERT_IDENT_KS_TYPE         | jks                    |
|  Identify Keystore Password | CERT_IDENT_KS_PWD          | 123456 [ 6 位以上 ]    |
|  Identity Private Key Alias | CERT_IDENT_KS_ALIAS        | ouaf_demo_cert_ident   |
|         Trust Keystore File | CERT_TRUST_KS_FILE         | [ 留空 ]               |
|    Trust Keystore File Type | CERT_TRUST_KS_TYPE         | jks                    |
|     Trust Keystore Password | CERT_TRUST_KS_PWD          | 123456 [ 6 位以上 ]    |
|     Trust Private Key Alias | CERT_TRUST_KS_ALIAS        | ouaf_demo_cert_trust   |

选择 7，根据提示按下表配置。

|                 Menu Option | Name Used in Documentation | Customer Install Value |
| --------------------------: | -------------------------- | ---------------------- |
| Import TrustStore Directory | TS_IMPORT_KEYSTORE_FOLDER  | [ 留空 ]               |
|                  Store Type | TS_STORETYPE               | JCEKS                  |
|                       Alias | TS_ALIAS                   | ouaf.system            |
|         Alias Key Algorithm | TS_ALIAS_KEYALG            | AES                    |
|              Alias Key Size | TS_ALIAS_KEYSIZE           | 128                    |
|                  HMAC Alias | TS_HMAC_ALIAS              | ouaf.system.hmac       |
|                     Padding | TS_PADDING                 | PKCS5Padding           |
|                        Mode | TS_MODE                    | CBC                    |

选择 P，开始安装

如果是第一次安装，安装过程中会提示运行脚本创建 cistab 文件并写入记录。

新建一个控制台，用 root 用户执行。

```shell
/var/tmp/ouaf/FW-V4.3.0.4.0-SP/cistab_ouaf_1.sh
```

回到安装脚本运行的控制台，输入 Y 继续。

> 注意，如果在运行 `cistab_ouaf_1.sh` 之后安装过程异常终止了，需要以 root 编辑 `/etc/cistab` 文件，删除其中的 `Environment Name` 如 `ouaf_1` 对应行。然后重新运行 install.sh 就可以重装了。

直至最后安装成功，下面是输出结果。

```plain
...
190907:191247 <info>  FW installation completed successfully, see the log /home/oracle/new-disk-1/software/FW-V4.3.0.4.0-SP4/install_FW_ouaf_1.log
Executing: /home/oracle/new-disk-1/ouafhome_1/ouaf_1/bin/splenviron.sh -e ouaf_1
JAVA_HOME=/usr/java/jdk1.8.0_221
WL_HOME=/home/oracle/new-disk-1/Oracle/Middleware/Oracle_Home/wlserver
Version ................ (SPLVERSION) : V4.3.0.4.0
Database Type ............... (CMPDB) : oracle
ORACLE_SID ............. (ORACLE_SID) : orcl
NLS_LANG ................. (NLS_LANG) : AMERICAN_AMERICA.AL32UTF8
Environment Name ....... (SPLENVIRON) : ouaf_1
Environment Code Directory (SPLEBASE) : /home/oracle/new-disk-1/ouafhome_1/ouaf_1
App Output Dir - Logs ... (SPLOUTPUT) : /home/oracle/new-disk-1/ouafhome_1/log/ouaf_1
```

安装后 OUAF 应用会自动启动，以后要启动或关闭 OUAF（及在 OUAF 基础上安装的 PSRM），可以使用下面命令。

```shell
$SPLEBASE/bin/spl.sh start
$SPLEBASE/bin/spl.sh stop
```

### 安装 PSRM 应用

如果上面的 OUAF 应用安装后直接执行后续的 PSRM 应用安装，相关环境变量就已经设置好了。
否则，需要在安装 PSRM 前，先用下述命令设置对应的环境（也即，在此情况下，要执行其他操作或者 postinstall 步骤，都需要先执行下述脚本设置环境）。

其中 $SPLEBASE 是 OUAF 安装的目录，如上文的 `/home/oracle/new-disk-1/ouafhome_1/ouaf_1` 目录。

```shell
$SPLEBASE/bin/splenviron.sh -e $SPLENVIRON
```

停止正在运行的 OUAF 应用。

```shell
$SPLEBASE/bin/spl.sh stop
```

#### 安装补丁包

解包补丁安装文件，修改 `FW-V4.3.0.4.0-Rollup/Application` 脚本运行权限，执行升级脚本。

```shell
jar -xvf PSRM-V25010-FW-PREREQ-MultiPlatform.jar

cd ./FW-V4.3.0.4.0-Rollup/Application
chmod a+x installSFgroup.sh
chmod a+x FW*/*.sh

./installSFgroup.sh
```

修改 `FW-V4.3.0.4.0-Rollup/Database/CDXPatch` 脚本运行权限，执行升级脚本。

```shell
cd ../../FW-V4.3.0.4.0-Rollup/Database/CDXPatch
chmod a+x *.sh

./ouafDatabasePatch.sh -p "-t O -d CISADM,ol7gui:1521:orcl"
```

#### 安装主应用

官网文档中要以 `cissys` 用户登录 Linux，我们单机安装一直使用的 `oracle` 用户，这里继续使用。

解包安装文件，执行安装脚本。

```shell
jar -xvf Release-PSRM-V2.5.0.1.0-Linux.jar
cd ./Release-TAX-V2.5.0.1.0-Linux/TAX.V2.5.0.1.0

chmod a+x install.sh

./install.sh
```

会显示一个配置清单，有 2， P， X 可以选。选择 2 后根据提示按下表配置。

|                            Menu Option | Name Used in Documentation | Customer Install Value |
| -------------------------------------: | -------------------------- | ---------------------- |
| JVM Child Process Starting Port Number |                            | 6503                   |
|          Number of JVM Child Processes |                            | 2                      |

然后选择 P 开始执行。

完成后，执行两个脚本。

```shell
$SPLEBASE/bin/splenviron.sh -e $SPLENVIRON
$SPLEBASE/bin/configureEnv.sh
```

提示输入时，按 P 直接执行。执行完再运行下面的脚本。

```shell
$SPLEBASE/bin/splenviron.sh -e $SPLENVIRON
$SPLEBASE/bin/initialSetup.sh
```

最后生成证书。

```shell
cd $SPLEBASE/bin
perl demo_gen_cert.plx
```

> 在 JDK 8 u161 以上版本运行 `perl demo_gen_cert.plx` 可能会报错 `java.security.InvalidKeyException: exponent is larger than modulus`，
> 这是一个已知 BUG，参见 https://docs.oracle.com/middleware/12213/wls/WLSRN/issues.htm#WLSRN-GUID-F1A75EF1-2B11-4CA6-85D8-D95B5F0DFD8E
>
> 解决办法是编辑 `$SPLEBASE/bindemo_gen_cert.plx` 文件，找到 `utils.CertGen -certfile` 字样，改为 `utils.CertGen -noskid -certfile`。
>
> 保存文件重新运行 `perl demo_gen_cert.plx` 命令。

运行过程中提示输入密码，就是上面 `Identify Keystore Password` 和 `Trust Keystore Password`。

至此安装全部成功，用以下命令启动 PSRM。

```shell
$SPLEBASE/bin/spl.sh start
```

启动后 PSRM 的页面访问地址为：https://ol7gui:6501/ouaf/loginPage.jsp

```shell
# 查看启动日志
cat /home/oracle/new-disk-1/ouafhome_1/ouaf_1/logs/system/spl.sh.log
# 运行日志监控
tail -f /home/oracle/new-disk-1/ouafhome_1/ouaf_1/logs/system/weblogic_current.log
```

## 日常操作

启动。

```shell
# 启动数据库
sqlplus /nolog
SQL> conn sys/sysadm as sysdba
SQL> startup
SQL> exit

# 启动监听
lsnrctl start

# 启动 weblogic admin
/home/oracle/new-disk-1/Oracle/Middleware/Oracle_Home/user_projects/domains/base_domain/startWebLogic.sh
## 访问地址 http://ol7gui:7001/console 用户名 weblogic/weblogic6

# 启动 PSRM(OUAF)
/home/oracle/new-disk-1/ouafhome_1/ouaf_1/bin/splenviron.sh -e ouaf_1
$SPLEBASE/bin/spl.sh start
```

## 附录

可以用 sqlplus 下面语句查询数据库 CIS* 对象，有助于确认是否正确创建了数据库结构。
如果 STATUS 里有 Invalid 字样要注意。

```sql
select owner,object_type, status,count(*) from dba_objects where owner like 'CIS%' group by owner,object_type, status order by 1,2;

--- OWNER OBJECT_TYPE STATUS COUNT(*)
-----------------------------------
```

> 找到一篇 Oracle CCB 的安装文字，虽不是同样应用，但都基于 OUAF，也可以借鉴参考。
> https://ccb2501.blogspot.com/2015/11/step-by-step-install-oracle-utilities.html

### 问题

启动不成功

修改了 $SPLEBASE/splapp/setEnv.sh 注释了 CLASSPATH 赋值和导出，因为其调用的 splapp/startWLS.sh 里也做了重复设置。

修改了 $SPLEBASE/splapp/startWebLogic.sh，改为了 `STARTMODE=false` 因为安装时选择的是开发模式。

修改了 $SPLEBASE/splapp/config.xml 里边感觉是大错特错，下面这段是改过后的设置。

```xml
    <realm>
      <sec:authentication-provider xsi:type="wls:default-authenticatorType">
        <sec:name>DefaultAuthenticator</sec:name>
      </sec:authentication-provider>
      <sec:authentication-provider xsi:type="wls:default-identity-asserterType">
        <sec:name>DefaultIdentityAsserter</sec:name>
        <sec:active-type>AuthenticatedUser</sec:active-type>
      </sec:authentication-provider>
      <sec:role-mapper xsi:type="xacml:xacml-role-mapperType">
        <sec:name>XACMLRoleMapper</sec:name>
      </sec:role-mapper>
      <sec:authorizer xsi:type="xacml:xacml-authorizerType">
        <sec:name>XACMLAuthorizer</sec:name>
      </sec:authorizer>
      <sec:adjudicator xseni:type="wls:default-adjudicatorType">
        <sec:name>DefaultAdjudicator</sec:name>
      </sec:adjudicator>
      <sec:credential-mapper xsi:type="wls:default-credential-mapperType">
        <sec:name>DefaultCredentialMapper</sec:name>
      </sec:credential-mapper>
      <sec:cert-path-provider xsi:type="wls:web-logic-cert-path-providerType">
        <sec:name>WebLogicCertPathProvider</sec:name>
      </sec:cert-path-provider>
      <sec:cert-path-builder>WebLogicCertPathProvider</sec:cert-path-builder>
      <sec:user-lockout-manager></sec:user-lockout-manager>
      <sec:security-dd-model>Advanced</sec:security-dd-model>
      <sec:combined-role-mapping-enabled>false</sec:combined-role-mapping-enabled>
      <sec:name>myrealm</sec:name>
    </realm>
```

但还是报错。

```plain
<Sep 8, 2019 2:39:59 AM GMT> <Critical> <WebLogicServer> <BEA-000386> <Server subsystem failed. Reason: A MultiException has 3 exceptions.  They are:
1. weblogic.management.ManagementException: [Management:141266]Parsing failure in config.xml: The following failures occurred:
-- Unresolved reference to WebLogicCertPathProvider by [splapp]/SecurityConfiguration[splapp]/Realms[myrealm]/CertPathBuilder
.
2. java.lang.IllegalStateException: Unable to perform operation: create on weblogic.management.provider.internal.RuntimeAccessImpl
3. java.lang.IllegalStateException: Unable to perform operation: post construct on weblogic.management.provider.internal.RuntimeAccessService
```

