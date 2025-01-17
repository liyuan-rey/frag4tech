# Apache Superset 的云上 kubernetes 部署

## 说明

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

## 使用方法

在云上 k8s 中：

- 查阅镜像仓库，确定要使用 `my-superset` 哪个版本，找到版本 imageUri
- 设置 k8s Deployment 采用上述镜像和版本
- 挂载 configmap 的配置文件
- 挂载持久化数据盘，块存储/文件存储/对象存储 各有优劣，目前用的 cfs 文件存储
- 设置相应的环境变量
- 设置装载路径
- 设置资源限额
- 设置 Service 参数（可选）

参考类似的 docker 命令：

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

> [!TIP]
> 如果是全新启动的 Deployment，面板默认登录账号 admin/admin，注意改密。

详细情况请参考：[在 Kubernetes 中部署 Apache Superset](./guide.md)
