# 使用 Apache Superset 官方镜像作为基础镜像
FROM apache/superset:3.1.3

USER root

# 腾讯 pip 源
#   内网 https://mirrors.tencentyun.com/pypi/simple
#   外网 https://mirrors.cloud.tencent.com/pypi/simple

# 安装 ClickHouse、Elasticsearch 和 PostgreSQL 数据库驱动并清理缓存
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install \
        -i https://mirrors.cloud.tencent.com/pypi/simple \
        --no-cache-dir \
        clickhouse-connect==0.8.6 \
        elasticsearch-dbapi==0.2.11 \
        psycopg2==2.9.10

USER superset
