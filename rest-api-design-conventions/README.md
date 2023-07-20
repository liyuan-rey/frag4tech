# REST API 接口设计约定

## 基本原则

API 遵循 REST 标准进行设计。

 API 应是 __可预期的__ 以及 __面向资源__ 的，接受 form-encoded 请求正文，返回 JSON-encoded 响应， 使用标准的 HTTP 响应代码 ，认证（OAuth 2.0）和参数。
所有请求和响应的编码均为 UTF-8。

## 基础返回字段

除了返回成功 HTTP Status Code 外，还在 Response Body 中携带如下 JSON 信息。

| 字段    |         类型          | 描述                                                                                |
| :------ | :-------------------: | :---------------------------------------------------------------------------------- |
| status  |        integer        | 必须。自定义返回状态码，可以和 HTTP Status Code 相同，如 200, 300, 20001            |
| message |        string         | 必须。返回信息。例如：成功描述，失败原因，错误异常等，                              |
| data    | Object \| Array\<any> | 必须。返回结果集。注意：不建议返回null或者undefine,应使用code错误码提示无返回数据。 |

## 分页和排序

分页请求示例参考： https://www.baeldung.com/spring-data-web-support#the-pageablehandlermethodargumentresolver-class

URL 形式为：

```url
http://ip:port/api/products?page=2&size=10&sort=name&sort=unitPrice,desc
```

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

| 字段      |  类型   | 描述                                                                     |
| :-------- | :-----: | :----------------------------------------------------------------------- |
| timestamp | string  | 必须。时间戳                                                             |
| status    | integer | 必须。自定义返回状态码，可以和 HTTP Status Code 相同，如 400, 500, 40001 |
| error     | string  | 必须。简要错误描述                                                       |
| exception | string  | 必须。异常信息                                                           |
| message   | string  | 必须。详细错误描述                                                       |
| path      | string  | 必须。请求 url                                                           |

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

URL Path 风格：`/qiming/{专项}/{版本号}/{子模块}/{资源}`

约定 Path 不使用英文复数表达，比如使用 person 不使用 people，使用 task 不使用 tasks

其中：
- 专项：专项业务标识，例如：cms（内容平台业务）、examine（考试业务）
- 版本号：接口版本号，例如：v1，v2 
- 子模块： 专项下子模块，如果没有可以省略，例如：task（任务子模块）
- 资源或业务对象名称，例如：person（业务模型）、car（业务模型）

```js

// 查询详情
GET     /qiming/cms/v1/person/1
// 查询集合，查询类业务参数首选使用 query param，需使用 POST Body 时需商议确定
GET     /qiming/cms/v1/person?page=1&keywords=xxx

// 新增业务
POST    /qiming/cms/v1/person

// 修改、更新类业务，简单业务的更新操作按 REST 标准约定为 PUT
PUT     /qiming/cms/v1/person/1
// 但有等保测评要求的不推荐使用 PUT（没必要跟测评单位拉扯技术点），改为使用 POST
POST    /qiming/cms/v1/person/1/put

# 删除类业务，简单业务的删除操作按 REST 标准约定为 DELETE
DELETE  /qiming/cms/v1/person/1
# 但有等保测评要求的不推荐使用 DELETE，改为使用 POST
POST    /qiming/cms/v1/person/1/delete

# 特殊业务，例如：重置，邀请等复杂业务
POST    /qiming/cms/v1/person/1/(reset|invite|...)

```

## 工具约定

约定在 Apifox 做接口设计。设计完成后可以选择把 API 设计结果导出为 OpenAPI 3.0 YAML 格式，然后导入腾讯云 CODING 项目中的 API 文档，以便使用。

原则上要求：

- 先在 Apifox 完成设计，再开始编码实现；
- 不使用 Apifox 的自动生成客户端代码；
- API 接口分类面向业务模块而非库表；

参考：
https://coding.net/help/docs/document/api/import/openapi.html
https://mermade.github.io/openapi-gui/
