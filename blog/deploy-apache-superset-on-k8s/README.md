# 在 Kubernetes 中部署 Apache Superset

## 简介

目标：

- 在 Kubernetes(k8s) 中部署 Apache Superset(superset)
- 在官方镜像中补充所需的驱动以便连接不同数据源
- 使用内置 SQLite 数据库保存元数据（也可以根据需要调整为MySQL、PostgreSQL等）
- 对 superset 的配置和元数据做持久存储，以便在重启或迁移时保持数据的连续性

验证环境：

- Windows 11 with WSL2
- WSL-Ubuntu 22.04 (WSL Distribution)
- Docker Desktop 4.35.1 with Kubernetes 1.30.2 (single node cluster)

## 文件说明

- 采用定制官方镜像的方式自定义镜像 `my-superset`

    基础镜像：`apache/superset:3.1.3`

    添加数据库连接组件

    - Clickhouse
    - Elasticsearch
    - PostgreSQL

    参考：https://superset.apache.org/docs/configuration/databases

- 提供了初始化后的密钥和数据库文件

    | 说明     | 文件名                            | 容器内路径                       |
    | -------- | --------------------------------- | -------------------------------- |
    | 密钥     | [./app/SUPERSET_SECRET_KEY](./app/SUPERSET_SECRET_KEY)       | -                                |
    | 元数据   | [./app/superset_home/superset.db](./app/superset_home/superset.db) | `/app/superset_home/superset.db` |
    | 示例数据 | [./app/superset_home/examples.db](./app/superset_home/examples.db) | `/app/superset_home/examples.db` |

- 提供了自定义配置文件

    | 说明       | 文件名                     | 容器内路径                |
    | ---------- | -------------------------- | ------------------------- |
    | 自定义配置 | [./app/superset_config.py](./app/superset_config.py) | `/app/superset_config.py` |

- 为初始化 Superset 动作提供了脚本

    - [./initdb/init_db.sh](./initdb/init_db.sh)

    参考：https://github.com/apache/superset/blob/3.1.3/docker/docker-init.sh

## 如何使用

- 先利用 [./Dockfile](./Dockfile) 构建镜像，并推送到镜像仓库。

    ```bash
    docker build -t my-superset:3.1.3 .
    ```

- 在本地运行验证

    ```bash
    docker run -d -p 8088:8088 \
        -e TZ=Asia/Shanghai \
        -e SUPERSET_SECRET_KEY=${SUPERSET_SECRET_KEY} \
        -e SUPERSET_CONFIG_PATH=/app/superset_config.py \
        -v ./superset_config.py:/app/superset_config.py \
        -v ./superset_home/superset.db:/app/superset_home/superset.db \
        -v ./superset_home/examples.db:/app/superset_home/examples.db \
        --name apache-superset
        my-superset:3.1.3
    ```

- 在云上 k8s 中部署

    - 查阅镜像仓库，确定要使用 `my-superset` 哪个版本，找到版本 imageUri
    - 设置 k8s Deployment 采用上述镜像和版本
    - 挂载 configmap 的配置文件
    - 挂载持久化数据盘，块存储/文件存储/对象存储 各有优劣，目前用的 cfs 文件存储
    - 设置相应的环境变量
    - 设置装载路径
    - 设置资源限额（可选）
    - 设置 Service 参数（可选）

    > [!TIP]
    > 如果是全新启动的 Deployment，面板默认登录账号 admin/admin，注意改密。

## 一步一步从头开始

### 准备 SUPERSET_SECRET_KEY

随机生成 SUPERSET_SECRET_KEY

```bash
SUPERSET_SECRET_KEY=$(openssl rand -base64 42)
echo ${SUPERSET_SECRET_KEY} > ./SUPERSET_SECRET_KEY

cat ./SUPERSET_SECRET_KEY
```

> [!IMPORTANT]
> 注意保存 SUPERSET_SECRET_KEY 密钥。
> 本文后续部署步骤中，此密钥用于启动 Superset，并初始化基础数据库。
> 在正式运行时，必须指定相配对的密钥和数据库，否则 Superset 将无法启动或启动后无法登录和正常使用。

### 获得数据库文件和配置样例文件

#### 基于官方镜像运行一个临时容器

```bash
# 启动容器并保持容器运行
docker run --rm -d \
    -e TZ=Asia/Shanghai \
    -e SUPERSET_SECRET_KEY=${SUPERSET_SECRET_KEY} \
    --name tmp_superset \
    apache/superset:3.1.3 /bin/bash -c "while true; do sleep 1000; done"
```

#### 在临时容器内初始化 SQLite 数据库

在上一步获得的临时容器内执行数据库初始化命令：

> 参考：https://github.com/apache/superset/blob/master/docker/docker-init.sh

```bash
# Applying DB migrations
docker exec -it -u superset tmp_superset superset db upgrade

# Create an admin user
# 创建的管理员账号 admin，密码为 admin，可以修改。
# 也可以在部署完成后，访问 Web 界面新建账号或修改 admin 账号的密码。
docker exec -it -u superset tmp_superset \
    superset fab create-admin \
        --username admin \
        --firstname Superset \
        --lastname Admin \
        --email admin@superset.com \
        --password admin

# Setting up roles and perms
docker exec -it -u superset tmp_superset superset init
```

> [!TIP] 说明
> `-u superset`：按照官方镜像约定的容器内用户 `superset` 身份执行命令。

如果需要示例数据（包括示例数据集、示例仪表盘等），可以继续执行：

```bash
# Loading examples
docker exec -it -u superset tmp_superset superset load_examples
```

> [!TIP]
> 示例数据需要从 github 上下载数据文件，国内访问速度较慢，可以提前配置代理。

到这里已经初始化好了 SQLite 数据库，实际形成的数据库文件包括：

- `/app/superset_home/superset.db`
- `/app/superset_home/examples.db` （如果加载了示例数据）

#### 拷贝数据库文件和配置样例文件

将初始化后的数据库文件和供参考的默认配置文件拷贝出来。
停止和清理掉临时容器。

```bash
mkdir -p ./superset_home

docker cp tmp_superset:/app/superset_home/superset.db ./superset_home/
docker cp tmp_superset:/app/superset_home/examples.db ./superset_home/
docker cp tmp_superset:/app/superset/config.py ./superset_config.sample

docker stop tmp_superset
```

> [!IMPORTANT]
> 建议将如下密钥文件和初始化数据库文件拷贝到其他地方管理起来，比如 Git 仓库或者云存储，避免后续部署过程中丢失。
>
> - `./SUPERSET_SECRET_KEY`
> - `./superset_home/superset.db`
> - `./superset_home/examples.db` （如果加载了示例数据）

拷贝默认配置文件 `/app/superset/config.py` 并不是必须的，拷贝出来的 `./superset_config.sample` 文件主要是供后续自定义配置时做参考。

### 创建自定义配置

Superset 配置文件本质上是一个 Python 代码模块。

用户自定义配置一般不建议直接修改 `/app/superset/config.py` 文件，应按照官方建议，重新创建自定义配置文件如 `superset_config.py`，并通过 `SUPERSET_CONFIG_PATH` 环境变量指定自定义配置文件的全路径，这样在 Superset 启动过程中会加载此文件并用自定义配置内容覆盖/合并配置项内容。

> [!TIP]
> 自定义配置项与默认配置项的差异处理策略有 `覆盖` 和 `合并` 两种，比如：
>
> - `DEFAULT_FEATURE_FLAGS` 是合并
> - `SQLALCHEMY_DATABASE_URI` 是覆盖
>
> 详细配置可以参考官方文档：https://superset.apache.org/docs/configuration/configuring-superset

下面的自定义配置文件 `superset_config.py` 中示例了几个常见的配置，供参考：

```python
# superset_config.py
"""The override config file for Superset

This is a override of the default config for Superset.
Note that '/app/superset/config.py' is the default config file for Superset.
"""
import os
from typing import Any, Callable, Literal, TYPE_CHECKING, TypedDict

if "SUPERSET_HOME" in os.environ:
    DATA_DIR = os.environ["SUPERSET_HOME"]
else:
    DATA_DIR = os.path.expanduser("~/.superset")

# Your App secret key. Make sure you override it on superset_config.py
# or use `SUPERSET_SECRET_KEY` environment variable.
# Use a strong complex alphanumeric string and use a tool to help you generate
# a sufficiently random sequence, ex: openssl rand -base64 42"
SECRET_KEY = os.environ.get("SUPERSET_SECRET_KEY") or CHANGE_ME_SECRET_KEY

# The SQLAlchemy connection string.
SQLALCHEMY_DATABASE_URI = (
    f"""sqlite:///{os.path.join(DATA_DIR, "superset.db")}?check_same_thread=false"""
)
# Try:
# SQLALCHEMY_DATABASE_URI = (
#     f"""{os.environ.get("SUPERSET_METADB_URI")}"""
# )
# use env like:
#     export SUPERSET_METADB_URI='sqlite:////app/superset_home/superset.db?check_same_thread=false'
#     export SUPERSET_METADB_URI='postgresql://superset:password@172.16.32.8:5432/superset

# Flask-WTF flag for CSRF
WTF_CSRF_ENABLED = True

# ---------------------------------------------------
# Roles config
# ---------------------------------------------------
# Grant public role the same set of permissions as for a selected builtin role.
# This is useful if one wants to enable anonymous users to view
# dashboards. Explicit grant on specific datasets is still required.
PUBLIC_ROLE_LIKE: str | None = 'Gamma'

# ---------------------------------------------------
# Feature flags
# ---------------------------------------------------
# Feature flags that are set by default go here. Their values can be
# overwritten by those specified under FEATURE_FLAGS in superset_config.py
# For example, DEFAULT_FEATURE_FLAGS = { 'FOO': True, 'BAR': False } here
# and FEATURE_FLAGS = { 'BAR': True, 'BAZ': True } in superset_config.py
# will result in combined feature flags of { 'FOO': True, 'BAR': True, 'BAZ': True }
DEFAULT_FEATURE_FLAGS: dict[str, bool] = {
    # Allow for javascript controls components
    # this enables programmers to customize certain charts (like the
    # geospatial ones) by inputting javascript in controls. This exposes
    # an XSS security vulnerability
    "ENABLE_JAVASCRIPT_CONTROLS": True,
    "VERSIONED_EXPORT": True,  # deprecated
    "EMBEDDED_SUPERSET": True,
}

# CORS Options
ENABLE_CORS = True
ALLOW_ORIGINS = ['http://192.168.101.129:8080','http://localhost:8080']
CORS_OPTIONS: dict[Any, Any] = {
    'supports_credentials': True,
    'allow_headers': ['*'],
    'resources':['*'],
    'origins': ALLOW_ORIGINS,
}

# If you want Talisman, how do you want it configured??
TALISMAN_CONFIG = {
    "content_security_policy": {
        "base-uri": ["'self'"],
        "default-src": ["'self'"],
        "frame-ancestors": ALLOW_ORIGINS,
        "img-src": ["'self'", "blob:", "data:"],
        "worker-src": ["'self'", "blob:"],
        "connect-src": [
            "'self'",
            "https://api.mapbox.com",
            "https://events.mapbox.com",
        ],
        "object-src": "'none'",
        "style-src": [
            "'self'",
            "'unsafe-inline'",
        ],
        "script-src": ["'self'", "'strict-dynamic'","'unsafe-eval'"],
    },
    "content_security_policy_nonce_in": ["script-src"],
    "force_https": False,
    "session_cookie_secure": False,
    "force_https_permanent": False,
    "frame_options": "ALLOWFROM",
    "frame_options_allow_from": "*",
}
```

### 扩展官方镜像以加载更多数据库连接组件

基于官方镜像 `apache/superset:3.1.3` 创建自定义镜像 `my-superset:3.1.3`，并添加更多数据库连接组件。

> 参考：https://superset.apache.org/docs/configuration/databases

编写 Dockerfile，参见 [./Dockerfile](./Dockerfile) 。

```dockerfile
# Dockerfile
FROM apache/superset:3.1.3

USER root

# 安装 ClickHouse、Elasticsearch 和 PostgreSQL 数据库驱动并清理缓存
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install \
        -i https://mirrors.cloud.tencent.com/pypi/simple \
        --no-cache-dir \
        clickhouse-connect==0.8.6 \
        elasticsearch-dbapi==0.2.11 \
        psycopg2==2.9.10

USER superset
```

> [!TIP]
> 腾讯 pip 源：
>
> - 内网 https://mirrors.tencentyun.com/pypi/simple
> - 外网 https://mirrors.cloud.tencent.com/pypi/simple

构建镜像。

```bash
docker build -t my-superset:3.1.3 .
```

### 准备持久化数据存储

> [!TIP]
> 这里的示例直接使用了主机文件系统的目录 `/mnt/my-storage/superset/` 作为 docker/k8s 的持久化存储，后续步骤会以此配置持久化。实际生产环境大多会使用云存储。

先拷贝初始化数据到持久化存储 `/mnt/my-storage/superset/`。

注意确认拷贝后的数据文件的权限。user:group 为 `1000:1000` 是官方镜像的默认用户。

作为参考，以下是直接在 Linux 主机上执行的命令示例（假定拷贝源文件在当前目录下 `./`）。

```bash
mkdir -p /mnt/my-storage/superset/superset_home

cp -r ./superset_config.py /mnt/my-storage/superset/
cp -r ./superset_home/*.db /mnt/my-storage/superset/superset_home/

chown -R 1000:1000 /mnt/my-storage/superset/*
```

现在是在 Docker Desktop 配置的 WSL 默认发行版 `Ubuntu` 中操作，所以要在 `Ubuntu` 的 Shell 中执行。

WSL 发行版中自动挂载了主机的文件系统，可以直接在 `/mnt/host/...` 路径上访问到主机的文件。

打开 PowerShell 执行以下命令。注意修改 `<your-file-path>`

```powershell
# 查看 wsl 发行版列表，标 * 的是默认发行版
wsl -l -v

# 用 root 用户在 wsl 指定发行版中创建目录
wsl -d docker-desktop -u root -- mkdir -p /mnt/my-storage/superset/superset_home
# 如果不指定，就是在默认发行版中创建
#wsl -u root -- mkdir -p /mnt/my-storage/superset/superset_home

# 绝对路径，指向 docker-desktop 中映射的 Win11 路径，如
# /mnt/host/c/Users/<username>/Documents/...
$WORK_DIR="<your-file-path>"

wsl -d docker-desktop -u root --cd $WORK_DIR -- cp -r ./superset_config.py /mnt/my-storage/superset/
wsl -d docker-desktop -u root --cd $WORK_DIR -- cp -r ./superset_home/*.db /mnt/my-storage/superset/superset_home/

wsl -d docker-desktop -u root -- chown -R 1000:1000 /mnt/my-storage/superset/*

Remove-Variable -Name WORK_DIR
```

最终持久化目录结构如下：

```plain
/mnt/my-storage/superset/
├── superset_config.py
└── superset_home
    ├── examples.db
    └── superset.db

1 directory, 3 files
```

### 在 Docker 容器中运行 Superset

通过 docker 运行 `my-superset` 来验证一下自定义镜像和持久化。

运行下面的 PowerShell 脚本，注意命令中挂载了持久化数据盘，挂载自定义配置文件。

```powershell
$SUPERSET_SECRET_KEY = Get-Content ./SUPERSET_SECRET_KEY

docker run -d -p 8088:8088 `
    -e TZ=Asia/Shanghai `
    -e SUPERSET_SECRET_KEY=$SUPERSET_SECRET_KEY `
    -e SUPERSET_CONFIG_PATH=/app/superset_config.py `
    -v /mnt/my-storage/superset/superset_config.py:/app/superset_config.py `
    -v /mnt/my-storage/superset/superset_home/superset.db:/app/superset_home/superset.db `
    -v /mnt/my-storage/superset/superset_home/examples.db:/app/superset_home/examples.db `
    --name apache-superset `
    my-superset:3.1.3

# 查看日志
docker logs -f apache-superset
```

启动完成后，就可以访问 Apache Superset 的 Web 界面了 http://localhost:8088 ，使用默认账户 `admin/admin` 登录，除非自行更改了账户。

容器重启后，数据不会丢失，因为数据存储在挂载的持久化数据盘上。

### 在 Kubernetes 中运行 Superset

在 Kubernetes 中运行，做法上和在 Docker 容器中类似，实际在运行 Pod 或者 Deployment 时做好相关配置：

- 设定环境变量 `SUPERSET_SECRET_KEY` 和 `SUPERSET_CONFIG_PATH`
- 将文件 `superset_config.py` 配置到 ConfigMap 并挂载到 `/app` 目录
- 将数据库文件 `superset.db` 和 `examples.db` 复制到持久化存储，配置数据卷并挂载到 `/app/superset_home` 目录
- 根据需要配置资源量及其他参数

下面是用 `kubectl` 命令行工具部署 Superset Deployment 的例子，采用 YAML 配置来描述，需要使用 `kubectl apply -f <file>` 命令来创建。

YAML 源文件请见： [./k8s/](./k8s/)

创建名字空间 `olap`。

```yaml
# namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: olap
```

```bash
kubectl apply -f namespace.yaml
```

创建 `ConfigMap`，用于挂载配置文件。限于篇幅，这里省略了配置文件内容，请自行添加。

```yaml
# configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: cm-superset-config
  namespace: olap
data:
  superset_config.py: |
    """The override config file for Superset

    This is a override of the default config for Superset.
    Note that '/app/superset/config.py' is the default config file for Superset.
    """
```

```bash
kubectl apply -f configmap.yaml
```

静态创建 PersistentVolume，用于持久化数据。使用了主机 `/mnt/my-storage/superset` 作为 k8s 存储卷，实际生产环境中大多会使用云存储。

```yaml
# pv.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-superset
  namespace: olap
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  local:
    path: /mnt/my-storage/superset/superset_home
  volumeMode: Filesystem
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - docker-desktop
```

```bash
kubectl apply -f pv.yaml
```

创建 PersistentVolumeClaim 并绑定数据卷。

```yaml
# pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-superset
  namespace: olap
spec:
  resources:
    requests:
      storage: 1Gi
  accessModes:
    - ReadWriteOnce
  storageClassName: local-storage
  volumeMode: Filesystem
  volumeName: pv-superset
```

```bash
kubectl apply -f pvc.yaml
```

创建 Deployment

> [!TIP]
> 注意修改 `your-secret-key` 为 SUPERSET_SECRET_KEY 的值。

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: apache-superset
  namespace: olap
spec:
  replicas: 1
  selector:
    matchLabels:
      app: apache-superset
  template:
    metadata:
      labels:
        app: apache-superset
    spec:
      volumes:
      - name: vol-superset-config
        configMap:
          name: cm-superset-config
          defaultMode: 420
      - name: vol-superset-data
        persistentVolumeClaim:
          claimName: pvc-superset
          readOnly: false
      containers:
      - name: apache-superset
        image: apache/superset:3.1.3
        ports:
        - containerPort: 8088
          protocol: TCP
        env:
        - name: TZ
          value: Asia/Shanghai
        - name: SUPERSET_SECRET_KEY
          value: "your-secret-key"
        - name: SUPERSET_CONFIG_PATH
          value: /app/superset_config.py
        volumeMounts:
        - mountPath: /app/superset_config.py
          name: vol-superset-config
          subPath: superset_config.py
          readOnly: true
        - mountPath: /app/superset_home
          name: vol-superset-data
          readOnly: false
```

```bash
kubectl apply -f deployment.yaml
```
