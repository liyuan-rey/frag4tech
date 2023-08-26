# HTTP API 接口设计约定（非 REST 风格）

## 基本原则

API 应是 __可预期__ 的以及 __可阅读__ 的，接受 form-encoded 请求正文，返回 JSON-encoded 响应， 使用标准的 HTTP 响应代码 ，认证（OAuth 2.0）和参数。
所有请求和响应的编码均为 UTF-8。

## 基础返回字段

除了返回成功 HTTP Status Code 外，还在 Response Body 中携带如下 JSON 信息。

| 字段    |         类型          | 描述                                                                                |
| :------ | :-------------------: | :---------------------------------------------------------------------------------- |
| status  |        integer        | 必须。自定义返回状态码，可以和 HTTP Status Code 相同，如 200, 300, 也可自定义 20001 |
| message |        string         | 必须。返回信息。例如：成功描述，失败原因，错误异常等，                              |
| data    | Object \| Array\<any> | 必须。返回结果集。注意：不建议返回null或者undefine,应使用code错误码提示无返回数据。 |

## 分页和排序

分页请求示例参考： https://www.baeldung.com/spring-data-web-support#the-pageablehandlermethodargumentresolver-class

URL 形式为：

```js
http://ip:port/api/products?page=2&size=10&sort=name&sort=unitPrice,desc
```

分页 query string 参数约定

| 字段 |  类型   | 描述                                                                                                               |
| :--- | :-----: | :----------------------------------------------------------------------------------------------------------------- |
| page | integer | 必须。获取的页码，不传参时默认为 0，而 0 是获取第一页                                                              |
| size | integer | 必须。获取记录数，不传参时默认为 10，最大 50                                                                       |
| sort | string  | 可选。可以有多个，每个都是逗号分隔的排序字段和排序关键字，排序关键字取值 'asc' 或 'desc'，关键字未指定时默认 'asc' |

分页返回字段约定

| 字段          |    类型     | 描述                        |
| :------------ | :---------: | :-------------------------- |
| totalElements |   integer   | 必须。总记录数              |
| size          |   integer   | 必须。每页记录数            |
| number        |   integer   | 必须。当前页，默认从 1 开始 |
| content       | Array\<any> | 必须。返回集合              |

注意，返回的分页数据内容应该被包裹在基础返回字段 data 中。

## 错误返回

除了返回错误 HTTP Status Code 外，还在 Response Body 中携带如下 JSON 信息。

| 字段      |  类型   | 描述                                                                                |
| :-------- | :-----: | :---------------------------------------------------------------------------------- |
| timestamp | string  | 必须。时间戳                                                                        |
| status    | integer | 必须。自定义返回状态码，可以和 HTTP Status Code 相同，如 404, 500, 也可自定义 40001 |
| error     | string  | 必须。简要错误描述                                                                  |
| exception | string  | 必须。异常信息                                                                      |
| message   | string  | 必须。详细错误描述                                                                  |
| path      | string  | 必须。请求 url                                                                      |

异常发生时返回结果的 Response Body 示例如下：

```json
{
    "timestamp": "2021-12-29 09:30:16",
    "status": 404,
    "error": "Not Found",
    "exception": "org.springframework.web.server.ResponseStatusException",
    "message": "Product not found, id: 1000",
    "path": "/products/1000"
}
```

## URL 命名规范

- 约定只使用 GET 和 POST 两个 HTTP 动词发起请求
- 约定 URL 全小写，尽量避免用特殊字符。(传参的 `query string` 的值或锚点内容不在此约束内)
- 约定 URL 采用短横线 `-` 分隔多个单词，包括 path 和 query string 中的键名
- 约定不使用英文复数表达，比如使用 person 不使用 people，使用 task 不使用 tasks

URL Path 风格：`/api/<子系统>/<版本号>/<模块>/<业务对象>/<动词或动词短语>`

其中：

- 子系统：子系统标识，例如 cms（内容平台业务）、project（项目管理业务）
- 版本号：接口版本号，例如 v1，v2
- 模块：子系统的模块，如果没有可以省略，例如 wbs（项目管理系统中的工作分解模块）
- 业务对象：例如 person、task
- 动词或动词短语：需要执行的动作

常用的动词有（建议而非约束）

| 词汇       | HTTP verb | 描述                                                                |
| :--------- | :-------: | :------------------------------------------------------------------ |
| create     |   POST    | 创建                                                                |
| update     |   POST    | 更新或修改                                                          |
| delete     |   POST    | 删除单个或批量删除，传参为 json 包裹的 ids 数组，一般实现为逻辑删除 |
| info       |    GET    | 获取符合条件的单个对象信息                                          |
| get-*      |    GET    | 获取符合业务诉求的单个对象信息，一般不会单写 `get` 动词             |
| get-*-list |    GET    | 获取符合业务诉求的列表信息                                          |
| find       |    GET    | 查询符合条件的对象列表，可以为空列表，不能为空值                    |
| search     |   POST    | 和 `find` 类似，但是为 POST 查询                                    |
| query      |   POST    | 多用于带统计性质的查询                                              |
| import     |   POST    | 导入，一般是从外部文件批量导入，返回结果和/或过程日志               |
| export     |   POST    | 导出，一般是将数据导出到外部文件，返回文件链接                      |

以下是一些示例

```js
// 获取单个租户信息
GET /api/cms/v1/tenant/info?id=10001
GET /api/cms/v1/tenant/info?name=百度在线网络技术（北京）有限公司

// 获取题目的正确答案，返回单个对象
GET /api/cms/v1/question/get-answer?question-id=60001

// 获取考试的正确答案，返回列表
GET /api/cms/v1/exam/get-answer?exam-id=80001
// 或者先找到考试对应的试卷，再找试卷的答案
GET /api/cms/v1/test-paper/get-answer?test-paper-id=70001

// 获取考生参加过的、正在进行中的考试列表
GET /api/cms/v1/exam/get-participated-list?examinee-id=20001&exam-status=1

// 获取考生的考试答案，返回列表
GET /api/cms/v1/exam/get-examinee-answer?exam-id=80001&examinee-id=20001

// 常规列表查询，默认就是分页查，不可以一次性返回全部数据
GET /api/cms/v1/tenant/find
GET /api/cms/v1/tenant/find?page=0&size=10&sort=name,asc&sort=update_time,desc

// 根据分类和题干关键字查询试题
POST /api/cms/v1/question/search
{
  stem_containing: "压缩机", 
  type: 1, // 单选题
  tags: [
    "班长"
  ],
  pageable: {
    page: 0,
    size: 10
  }
}

// 获取答错率最高的前 5 道试题
// 较耗资源的操作采用 POST 一定程度避免拷贝链接后误调用引起的资源消耗
POST /api/cms/v1/question/query-top-wrong-rate
{
  limit: 5
}

// 导出试卷，高耗操作还是采用 POST
POST /api/cms/v1/test-paper/export
{
  id: 70001,
  output_type: "docx"
}
```

## 工具约定

约定在 Apifox 做接口设计。设计完成后可以选择把 API 设计结果导出为 OpenAPI 3.0 YAML 格式，然后导入腾讯云 CODING 项目中的 API 文档，以便使用。

建议：

- 先在 Apifox 完成设计，再开始编码实现；
- 不使用 Apifox 的自动生成客户端代码；
- API 接口分类面向业务模块而非库表；

参考：
https://coding.net/help/docs/document/api/import/openapi.html
https://mermade.github.io/openapi-gui/
