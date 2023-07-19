# Java 服务端开发约定

## 1. 技术选型

### 1.1. 基础设施

|    技术点    |     选型      |  版本   | 说明             |
| :----------: | :-----------: | :-----: | ---------------- |
|  关系数据库  |  PostgreSQL   |  13.6+  |
|   缓存服务   |     Redis     |  6.2+   |
|   对象存储   |     MinIO     | 202202+ | 基于 S3 协议访问 |
|  日志和检索  | Elasticsearch |         |
| 统一认证服务 |   KeyCloak    |         |
|   API 网关   |    APISIX     | 2.15.0+ |

### 1.2. Java 开发

|     技术点     |             选型              |         版本         | 说明                                        |
| :------------: | :---------------------------: | :------------------: | ------------------------------------------- |
|    编程语言    |             Java              |          17          |                                             |
|    构建工具    |            Gradle             |         7.4+         | 默认采用自宿主（Tomcat）方式构建为 jar 包   |
|    核心框架    |          Spring Boot          |        2.7.2+        |
|      日志      | spring boot logging + logback | Spring Boot 依赖管理 |                                             |
|    ID 生成     |         UidGenerator          |                      |
| 数据访问-pgSQL |        spring-data-jpa        | Spring Boot 依赖管理 |
| 数据访问-Redis |       spring-data-redis       | Spring Boot 依赖管理 |
| 数据访问-MinIO |    MinIO Java SDK for  S3     |                      | https://github.com/minio/minio-java         |
|  数据访问-ES   |        spring-data-es         | Spring Boot 依赖管理 |
|      IDE       |         IntelliJ IDEA         |       较新版本       |
|  代码生成插件  | Lombok, Easy Code, JPA Buddy  |       较新版本       |
|  代码检查插件  |           SonarLint           |       较新版本       | alibaba-java-coding-guidelines 可以自选使用 |

## 2. 编码规范和检查

- 持续集成中使用 SonarQube 进行自动化检查，无 SonarQube 时可采用 Checkstyle 9.2.1+PMD(Alibaba)
- 本地开发可以使用 IDE 的 SonarLint 插件作代码质量检查辅助工具，可选在 IDE 中使用“阿里规约”插件做辅助检查

## 3. 包命名规范

总体包命名规范：

- **项目前缀**：com.chuangze.qiming
- **模块前缀**：com.chuangze.qiming.[模块名称].

各个模块内部包命名规范：

- 通用基础类 common，内部工程名 `qiming-common`

    | 包名                 |                说明                |
    | :------------------- | :--------------------------------: |
    | [项目前缀].enumerate |             通用枚举包             |
    | [项目前缀].error     |        通用异常和错误处理包        |
    | [项目前缀].dto       | 通用模型包，如分页模型、返回模型。 |
    | [项目前缀].util      |              工具类包              |

- 业务服务类 service，内部工程名 `qiming-[xxx业务工程]-service`

    | 包名                                |              说明               |
    | :---------------------------------- | :-----------------------------: |
    | [模块前缀].entity                   |            持久化类             |
    | [模块前缀].entity.metadata          |      持久层枚举属性转化类       |
    | [模块前缀].repository               |            持久层包             |
    | [模块前缀].repository.specification |        持久层查询定义包         |
    | [模块前缀].service                  |          业务服务层包           |
    | [模块前缀].service.impl             |        业务服务实现层包         |
    | [模块前缀].datamapper               | 数据转换（持久化<<=>>数据传输） |
    | [模块前缀].dto                      |   数据传输对象，对业务层参数    |
    | [模块前缀].enumerate                |    作用范围为本业务的枚举包     |
    | [模块前缀].exception                |    作用范围为本业务的异常包     |

- 业务API类 webapi，内部工程名 `qiming-[xxx业务工程]-webapi`

    | 包名                   |     说明     |
    | :--------------------- | :----------: |
    | [项目前缀].config      | spring配置包 |
    | [项目前缀].interceptor |    拦截器    |
    | [模块前缀].controller  |   控制层包   |

- 其他可选命名

   | 包名                             |            说明            |
   | :------------------------------- | :------------------------: |
   | [模块前缀].listener              |       业务逻辑监听器       |
   | [模块前缀].manager               | 通用业务，用户信息、字典等 |
   | [项目前缀].[第三方业务].client   |    第三方业务客户端逻辑    |
   | [项目前缀].[第三方业务].request  |      第三方业务请求包      |
   | [项目前缀].[第三方业务].response |      第三方业务响应包      |

## 4. 代码工程结构

### 4.1. 工程结构

```plain
├── qiming-training-server          # 培训模块 java 后端工程 git 仓库
│└── qiming-training-service          # 培训业务类库
│└── qiming-training-webapi           # 培训 spring boot rest web service
├── qiming-examination-server       # 考试模块 java 后端工程 git 仓库
│└── qiming-examination-service       # 考试业务类库
│└── qiming-examination-webapi        # 考试 spring boot rest web service
```

### 4.2. 内部包结构

```plain
├─qiming-training-service
│  └─src
│      ├─main
│      │  ├─java
│      │  │  └─com
│      │  │      └─gsafety
│      │  │          └─qiming
│      │  │              ├─training
│      │  │              │  ├─dto
│      │  │              │  ├─entity
│      │  │              │  │  └─metadata
│      │  │              │  ├─enumerate
│      │  │              │  ├─exception
│      │  │              │  ├─repository
│      │  │              │  │  └─specification
│      │  │              │  ├─service
│      │  │              │  │  └─impl
│      │  │              │  └─datamapper
│      │  │              └─module2
│      │  └─resources
│      └─test
│          ├─java
│          └─resources
└─qiming-training-webapi
    └─src
        ├─main
        │  ├─java
        │  │  └─com
        │  │      └─gsafety
        │  │          └─qiming
        │  │              ├─training
        │  │              │  └─controller
        │  │              └─module2
        │  │                  └─controller
        │  └─resources
        └─test
            ├─java
            └─resources
```

## 5. 制品约定

### 5.1. 文件制品

制品文件名称：`[代码工程名称]-[版本号]`

其中：

- `[版本号]` 为：`主版本号.次版本号.修订版本号`
- `[代码工程名称]` 基本用词约定如下

    |    单词     | 含义                               |
    | :---------: | ---------------------------------- |
    |   qiming    | 是项目代号 **启明星** 的汉语拼音   |
    |  training   | 培训模块                           |
    | examination | 考试模块                           |
    |  practice   | 演练模块                           |
    |   service   | 业务类库部分的代码                 |
    |   webapi    | Spring Boot RESTful API 部分的代码 |

如：

- 培训模块
  - 业务类库制品：qiming-training-service-1.0.1.jar
  - REST API 制品：qiming-training-webapi-1.1.0.jar
- 考试模块
  - 业务类库制品：qiming-examination-service-1.0.1.jar
  - REST API 制品：qiming-examination-webapi-1.1.0.jar

### 5.2. 镜像制品

镜像制品名称： `DOCKER_REGISTRY/repo/name:tag`

我们日常使用的镜像名称的通用格式为：DOCKER_REGISTRY/repo/name:tag，各个字段具体含义如下。

- `DOCKER_REGISTRY`：企业统一的 Docker Registry 地址；使用：172.22.3.5:9002
- `repo`：镜像仓库，用来管理某一类镜像；本项目中是：qiming
- `name`：某个镜像的具体名称。
- `tag`：某个镜像具体的标签。例如：2.0.0。

参考 docker hub 内镜像命名如：wordpress（wordpress:6.1.1-php8.1-fpm、wordpress:6.1.1-php8.1）、kong（kong/kong-gateway:3.1.0.0-ubuntu、kong/kong-gateway:3.1.0.0-ubuntu、kong/kong-gateway:3.1.0.0-debian），可见各服务提供商对name一般不会添加版本号，将只在tag中添加版本或特殊信息。

关于name，需要注意的是：

- 镜像的名称需要限制为[a-z0-9]，其中可以出现的符号为[-._]
- 连接符（-）不能连续出现、不能单独注册，也不能放在开头和结尾。
- 不能出现中文以及中文符号，包括镜像名称中的冒号 `:` 也必须是英文的冒号，不然创建容器的时候会失败。
- 域名长度不超过63个字符。

建议镜像制品name使用：

- 服务端：qiming-专项名-webapi，例如：qiming-training-webapi
- 客户端：qiming-xxx-site，例如：qiming-cms-site

关于tag，每个镜像提供商标准不同，如：

- nginx（1.19.6，mainline，1.19，latest，1.19.6-perl，mainline-perl）
- redis（7.0.5、7.0-bullseye、latest）
- kafka（3.3.1-debian-11-r21、3.3.1、latest）

建议镜像制品tag使用：

- 标准：1.0.1
- 测试（临时）：0.0.1-test ，用于各专项构建临时版本做测试使用。
- 信创云生产环境（可能）：1.0.1-qilin10.1

最终：

镜像名称：172.22.3.5:9002/qiming/[代码工程名称]:[版本号]

例子：172.22.3.5:9002/qiming/qiming-training-webapi:1.0.1

## 6. 容器镜像构建约定

为了简化系统部署复杂度，本项目内的业务服务均采用容器化部署方式。

如果使用云端（如腾讯云 CODING DevOps）持续构建环境，则按云端工具文档操作。

如果是自建的环境中构建镜像，在 Spring Boot 项目中推荐采用 “Spring Boot Maven and Gradle Plugins” 提供的内置能力构建容器镜像。

例如，使用 Gradle 时

```shell
./gradlew bootBuildImage --imageName=myorg/myapp
```

或者，使用 Maven 时

```shell
./mvnw spring-boot:build-image -Dspring-boot.build-image.imageName=myorg/myapp
```

构建镜像需要具备 Docker daemon 支持（本地或远程皆可）。第一次构建镜像需要下载 JDK 基础镜像，会花一些时间，后续构建会很快。

## 7. 附：关于事务处理的一些经验

### 7.1. 避免大事务

- 错误写法

    ```java
    @Service
    public class DemoServiceImpl{

        @Autowired
        XXXSerivce xxxSerivce;

        @Autowired
        BBBSerivce bbbSerivce;

        @Autowired
        CCC1Serivce ccc1Serivce;


        @Transactional
        public void bus() {
            Entytiy1 entytiy1 = xxxSerivce.queryXXX();
            Entytiy2 entytiy2 = bbbSerivce.rpcBBB();
            Entytiy3 entytiy3 = ccc1Serivce.rpcCCCC();

            ccc1Serivce.save(entytiy1, entytiy2, entytiy3);
            afterhandle();
        }

        public void afterhandle() {
            xxxSerivce.xxx();
        }
    }
    ```

- 正确写法

    ```java
    @Service
    public class DemoServiceImpl{

        @Autowired
        XXXSerivce xxxSerivce;

        @Autowired
        BBBSerivce bbbSerivce;

        @Autowired
        CCC1Serivce ccc1Serivce;

        public void bus() {

            Entytiy1 entytiy1 = xxxSerivce.queryXXX();
            Entytiy2 entytiy2 = bbbSerivce.rpcBBB();
            Entytiy3 entytiy3 = ccc1Serivce.rpcCCCC();
    
            demoService.save(entytiy1, entytiy2, entytiy3);
            afterhandle();
        }

    public void afterhandle() {
            xxxSerivce.xxx();
        }

        @Transactional
        public void save(Entytiy1 a, Entytiy2 b, Entytiy1 c) {
            ccc1Serivce.save(a, b, c)
        }
    }
    ```

### 7.2. 事务失效

- 错误写法

    ```java
    public void save(User user) {
            queryData1();
            queryData2();
            doSave();
        }
    
        @Transactional(rollbackFor=Exception.class)
        public void doSave(User user) {
        addData1();
        updateData2();
        }
    ```

- 正确写法

    ```java
    @Servcie
    publicclass ServiceA {
        @Autowired
        prvate ServiceA serviceA;

        public void save(User user) {
            queryData1();
            queryData2();
            serviceA.doSave(user);
        }
        
        @Transactional(rollbackFor=Exception.class)
        public void doSave(User user) {
            addData1();
            updateData2();
        }
    }
    ```

### 7.3. 其他

- 禁止在事务方法中调用三方服务api
