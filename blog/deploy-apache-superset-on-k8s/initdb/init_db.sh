#!/usr/bin/env bash

set -eo pipefail

echo $(pwd)

# 构建自定义镜像
imageName=my-superset && echo ${imageName}
baseVersion=$(cat ./Dockerfile | grep ^FROM | awk -F ':' '{print $2}') && echo ${baseVersion}
shortCommitId=$(git rev-parse --short HEAD) && echo ${shortCommitId}
# imageVersion=${baseVersion}-${shortCommitId} && echo ${imageVersion}
imageNameVersion=${imageName}:${baseVersion}-${shortCommitId} && echo ${imageNameVersion}

docker build -t ${imageNameVersion} .
docker image ls

# 随机生成 SUPERSET_SECRET_KEY，注意保存，后续启动容器时需要传入
SUPERSET_SECRET_KEY=$(openssl rand -base64 42)
echo ${SUPERSET_SECRET_KEY} > ./superset_home/SUPERSET_SECRET_KEY
# cat ./superset_home/SUPERSET_SECRET_KEY

# 运行自定义镜像，执行数据库初始化操作并持久化到本地，方便后续启动容器时挂载
# 默认初始化 admin 用户密码为 admin，可通过 ADMIN_PASSWORD 环境变量修改
container_id=$(docker run -d -p 8088:8088 \
        -e TZ=Asia/Shanghai \
        -e SUPERSET_SECRET_KEY=${SUPERSET_SECRET_KEY} \
        -e ADMIN_PASSWORD=admin \
        -e SUPERSET_LOAD_EXAMPLES=yes \
        ${imageNameVersion} /app/docker-entrypoint-initdb.d/superset_init.sh) \
        || { echo "Failed to start container"; exit 1; }

# 在交互式构建测试时用的命令，可忽略
# docker run -it -p 8088:8088 \
#     -e TZ=Asia/Shanghai \
#     -e SUPERSET_SECRET_KEY=${SUPERSET_SECRET_KEY} \
#     -e ADMIN_PASSWORD=admin \
#     -e SUPERSET_LOAD_EXAMPLES=yes \
#     ${imageNameVersion} /bin/bash -c "/app/docker-entrypoint-initdb.d/superset_init.sh && tail -f /dev/null"
# tail -f /dev/null


# 等待容器执行完成，如果容器执行失败，输出容器日志
docker wait ${container_id}

if [ $(docker inspect -f '{{.State.ExitCode}}' ${container_id}) -ne 0 ]; then
    docker logs ${container_id}
    exit 1
fi

# 复制 container_id 容器内初始化的数据库文件到本地本地 superset_home 目录
docker cp -a ${container_id}:/app/superset_home/superset.db ./superset_home/
docker cp -a ${container_id}:/app/superset_home/examples.db ./superset_home/

# 上述执行都成功后再上传镜像
uploadUrlServer=liyuan-rey-docker.pkg.coding.net && echo ${uploadUrlServer}
uploadUrlPath=my/devops && echo ${uploadUrlPath}
imageUri=${uploadUrlServer}/${uploadUrlPath}/${imageNameVersion} && echo ${imageUri}

docker tag ${imageNameVersion} ${imageUri}

echo $CODING_PROJECT_TOKEN | docker login -u $CODING_PROJECT_TOKEN_USER_NAME --password-stdin ${uploadUrlServer}
docker push ${imageUri}
docker logout ${uploadUrlServer}


# 提交初始化后的数据库文件
echo ${CODING_REPO_URL_HTTPS}

# 设置 git 用户信息
# 参考 https://ci.coding.net/docs/plugins/public/tencentcom/git-set-credential
# git config user.name ${CODING_COMMITTER} # ${CODING_BUILD_USER} 为显示名称，如 张三
# git config user.email ${CODING_COMMITTER_EMAIL} # ${CODING_BUILD_USER_EMAIL} 可能为空
# gitCredentialsStore=$(pwd)/../.git/.git-credentials
# echo "https://${CODING_PROJECT_TOKEN_USER_NAME}:${CODING_PROJECT_TOKEN}@e.coding.net/${CODING_REPO_SLUG}.git" >> ${gitCredentialsStore}
# git config credential.helper "store --file=${gitCredentialsStore}"
# cat ${gitCredentialsStore}

git status

git add ./superset_home/SUPERSET_SECRET_KEY
git add ./superset_home/superset.db
git add ./superset_home/examples.db

git commit -m "ci: update superset db file after init db"

git push origin HEAD:${CODING_BRANCH}

# 删除敏感文件
rm -rf ./superset_home/SUPERSET_SECRET_KEY
# rm -rf .git/.git-credentials

# 删除临时容器
docker rm ${container_id}

# 删除本地镜像
docker rmi ${imageNameVersion}
# docker rmi ${imageUri}

exit 0

######################################################################
# 以下为后续启动容器时的命令
# 后续启动容器时，需要传入 SUPERSET_SECRET_KEY 环境变量，以及挂载 superset_home 目录
# 如果有自定义配置文件，需要指明 SUPERSET_CONFIG_PATH 环境变量，并将配置文件挂载
# 到 /app/superset_home/superset_config.py
# 例如：
# docker run -d -p 8088:8088 \
#     -e TZ=Asia/Shanghai \
#     -e SUPERSET_SECRET_KEY=${SUPERSET_SECRET_KEY} \
#     -e SUPERSET_CONFIG_PATH="/app/superset_home/superset_config.py" \
#     -v ./superset_home:/app/superset_home \
#     -v ./superset_config.py:/app/superset_home/superset_config.py:ro \
#     ${imageUri})
######################################################################
