# 使用 JPA 访问 JSONB 字段

## 适用场景和依赖选择

使用 JPA 访问 PostgreSQL 的 JSON/JSONB 字段时，需要把 Java 数据类型和数据库字段建立映射关系。常见做法有三类：

- 将 JSON 字段映射为 `String`，读写前由应用自行序列化和反序列化。
- 使用 Hibernate 6 内置 JSON 映射能力。
- 使用 Hypersistence Utils 等开源库，减少重复的类型转换代码。

本文以 Hypersistence Utils 为例。使用前应根据项目所使用的 Spring Boot 和 Hibernate 版本选择对应 artifact：

- Spring Boot 2.x / Hibernate 5：`hypersistence-utils-hibernate-55`
- Spring Boot 3.x / Hibernate 6：`hypersistence-utils-hibernate-62`、`hypersistence-utils-hibernate-63` 等，应按当前 Hibernate 版本选择

依赖版本会随 Hibernate 兼容性调整，建议以 Hypersistence Utils 官方 README 的当前说明为准。

## 引入依赖

Gradle 示例：

```groovy
ext {
    hypersistenceUtilsVersion = "3.7.0"
}

dependencies {
    // 以 Spring Boot 2.x / Hibernate 5 为例
    implementation "io.hypersistence:hypersistence-utils-hibernate-55:${hypersistenceUtilsVersion}"
}
```

如果项目使用 Spring Boot 3.x，应将 artifact 替换为与 Hibernate 6 匹配的版本，并检查注解写法差异。

## 定义实体

以一张包含 JSONB 字段的表为例：

```sql
CREATE TABLE r_tag_label_payload (
    id BIGINT PRIMARY KEY,
    tag_ids JSONB NOT NULL
);
```

`tag_ids` 字段的数据结构示例：

```json
{
  "ids": [7, 8, 9]
}
```

### Hibernate 5 写法

Spring Boot 2.x 通常使用 Hibernate 5，可以通过 `@TypeDef` 注册自定义类型：

```java
@Entity
@Table(name = "r_tag_label_payload")
@TypeDef(name = "json", typeClass = JsonType.class)
public class TagLabelPayload {

    @Id
    @Column(name = "id")
    private Long id;

    @Type(type = "json")
    @Column(name = "tag_ids", columnDefinition = "jsonb")
    private Map<String, Object> tagIds = new HashMap<>();

    // 省略 getter 和 setter
}
```

### Hibernate 6 写法

Hibernate 6 已经增强了对 JSON 类型的内置支持。可以按 Hypersistence Utils 当前文档使用其 `JsonType`，也可以使用 Hibernate 内置的 `@JdbcTypeCode(SqlTypes.JSON)`：

```java
@Entity
@Table(name = "r_tag_label_payload")
public class TagLabelPayload {

    @Id
    @Column(name = "id")
    private Long id;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "tag_ids", columnDefinition = "jsonb")
    private Map<String, Object> tagIds = new HashMap<>();

    // 省略 getter 和 setter
}
```

升级到 Spring Boot 3 时，应重点检查 `javax.persistence` 到 `jakarta.persistence`、Hibernate 注解以及自定义类型注册方式的变化。

## 定义 Repository

```java
public interface TagLabelPayloadRepository
        extends JpaRepository<TagLabelPayload, Long> {
}
```

## 读写 JSONB 字段

```java
@Service
public class TagLabelPayloadService {

    private final TagLabelPayloadRepository repository;

    public TagLabelPayloadService(TagLabelPayloadRepository repository) {
        this.repository = repository;
    }

    public void write() {
        Map<String, Object> tagIds = new HashMap<>();
        tagIds.put("ids", List.of(7L, 8L));

        TagLabelPayload entity = new TagLabelPayload();
        entity.setId(5L);
        entity.setTagIds(tagIds);

        repository.save(entity);
    }

    public Map<String, Object> read(Long id) {
        return repository.findById(id)
                .map(TagLabelPayload::getTagIds)
                .orElse(Map.of());
    }
}
```

## 使用 JSONB 条件查询

下面的示例查询 `tag_ids.ids` 数组中是否包含指定数值：

```java
public interface TagLabelPayloadRepository
        extends JpaRepository<TagLabelPayload, Long> {

    @Query(
        value = """
            SELECT s.*
            FROM r_tag_label_payload s
            WHERE s.tag_ids -> 'ids' @> to_jsonb(CAST(:id AS bigint))
            """,
        nativeQuery = true
    )
    List<TagLabelPayload> queryByIdInJson(@Param("id") Long id);
}
```

常用 JSONB 操作符：

- `->`：从 JSONB 对象按键取值，或从 JSONB 数组按索引取值，返回 JSONB。
- `->>`：取值并转换为文本。
- `@>`：判断左值是否完整包含右值。
- `@?`：判断 JSON 路径是否存在匹配结果。

示例：

```sql
SELECT *
FROM r_tag_label_payload
WHERE tag_ids -> 'ids' @> '7';
```

## 注意事项

- JSONB 字段适合保存结构相对灵活的补充信息，不应滥用 JSONB 规避关系建模。
- 高频过滤字段应结合查询计划评估 GIN 索引等优化手段。
- 应用侧应校验 JSON 结构，避免把无效结构写入数据库。
- 使用原生 SQL 时应使用绑定参数，避免拼接 SQL 造成注入风险。
- 单元测试和集成测试应覆盖序列化、反序列化和数据库查询三个环节。

## 参考资料

- [Hypersistence Utils](https://github.com/vladmihalcea/hypersistence-utils)
- [PostgreSQL JSON Functions and Operators](https://www.postgresql.org/docs/current/functions-json.html)
