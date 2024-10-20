# 使用 JPA 访问 JSONB 字段

使用 JPA 访问 JSONB 字段时，需要将 Java 的数据类型和数据库表的 JSON/JSONB 类型字段建立对应关系，可以自行实现相应的映射转换代码，也可以借助第三方库实现。Java 数据类型可以是 String、数组、HashMap 甚至自定义数据类型（POJO）。

这里以开源第三方工具库为基础，演示如何存取 JSONB 字段。

第三方工具库：https://github.com/vladmihalcea/hypersistence-utils

可以参考 README.md 文件中的说明，摘要如下。

引用第三方库依赖，并用版本变量统一管理版本号：

```groovy

  // build.gradle

  hypersistence-utils.version = '3.7.0'
  implementation "io.hypersistence:hypersistence-utils-hibernate-55:${hypersistence-utils.version}"

```

在 Spring Boot 2.x 中，定义实体类 Entity：

> Spring Boot 2.x 和 Spring Boot 3 写法有差异，具体请参考官网文档。

```java

// TagLabelPayload.java

@Entity
@Table(name="r_tag_label_payload")
@TypeDef(name = "json", typeClass = JsonType.class)
public class TagLabelPayload {

    @Id
    @Column(name = "id")
    private Long id;

    @Type(type = "json")
    @Column(name = "tag_ids", columnDefinition = "jsonb")
    private Map<String, Object> tagIds = new HashMap<>();
}

```

设定 JSON 字段的结构示例如下：

```json
{
  "ids": [7, 8, 9]
}
```

写个简单的 Repository，仅继承 JpaRepository 原有能力：

```java

// TagLabelPayloadRepository.java

public interface TagLabelPayloadRepository extends JpaRepository<TagLabelPayload, Long> {
}

```

读写数据的例子：

```java

    // 写入数据
    public void write() {
      var ids = new HashMap<String, Object>();
      ids.put("tag_ids", new Long[] {7L, 8L});

      TagLabelPayload entity = new TagLabelPayload();
      entity.setId(5L);
      entity.setTagIds(ids);

      repository.save(entity);
    }

    // 读取数据
    public void read() {
        Optional<TagLabelPayload> record = repository.findById(8L);
        var ids = record.isPresent() ? record.get().getTagIds() : new Long[]{};
    }

```

如果要对 JSON 字段的内容进行筛选，可以扩充 Repository 方法，比如：

```java

// TagLabelPayloadRepository.java

public interface TagLabelPayloadRepository extends JpaRepository<TagLabelPayload, Long> {

    // 在 JSON 字段中匹配指定路径 ids 下的内容是否【完全包含】指定值
    @Query(value = "SELECT s.* FROM r_tag_label_payload s WHERE s.tag_ids->'ids' @> '[:id]'", nativeQuery = true)
    List<TagLabelPayload> queryByIdInJson(@Param("id") Long id);
}

```

更多的查询写法示例：

```sql

SELECT
  *,
  tag_ids->'tag_ids'
FROM
  "r_tag_label_payload"
WHERE
  ( ID = 5 )
   -- 匹配 JSON 路径是否包含某一元素
  AND ( tag_ids->'tag_ids' @? '$ ? (@==7 || @==9)' )

```

解析一下：

在 `s.tag_ids->'ids' @> '[:id]'` 这个表达式中，`@>` 是 jsonb 的特定操作符，用于检测左值 JSONB 是否【在顶层完全包含】右值。

例如：`'{"a":1, "b":2}'::jsonb @> '{"b":2}'::jsonb` 返回真。（`::jsonb` 是类型转换，把字符串转成 jsonb，本身就是 jsonb 的字段不必转换）

另外，表达式 `tag_ids->'tag_ids' @? '$ ? (@==7 || @==9)'`

...

更多的 PostgreSQL 的 WHERE 子句 中的 JSON 查询表达式写法参考：

PostgreSQL 官网文档：https://www.postgresql.org/docs/12/functions-json.html

中文参考（部分术语翻译不准，容易引起理解偏差）：http://postgres.cn/docs/12/functions-json.html

