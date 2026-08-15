# 储备文章发布处理 TODO

本文档整理当前储备文章的评估结论、发布批次和后续处理事项，作为站点内容整理工作的执行参考。

## 1. 背景与关键结论

当前站点虽然只在首页、导航和侧边栏挂载了两篇文章：

- HTTP API 接口设计约定（非 REST 风格）
- PostgreSQL 数据库设计和开发指南

但 VitePress 会构建源码中的所有 Markdown 文件。因此，储备文章虽然没有入口，仍会生成可访问页面。后续应通过 `_drafts` 目录和 `srcExclude` 明确区分“已发布”和“暂不发布”的内容。

已发布文章的约定：

- 文章目录使用描述性 kebab-case 命名。
- 正式文章入口统一使用 `index.md`。
- 页面链接统一使用 `/blog/<article>/` 形式。
- 正文以一级标题开始，文章相关图片和示例文件放在同一目录。
- 首页 action、导航和侧边栏只挂载达到发布状态的文章。

## 2. 站点基础整理

### 2.1 增加草稿隔离机制

- [x] 创建 `blog/_drafts/` 目录，用于保存暂不发布和待整理文章。
- [x] 在 `.vitepress/config.mjs` 中排除草稿目录，例如：

    ```js
    srcExclude: ["blog/_drafts/**"],
    ```

- [x] 确认草稿目录中的文章不再出现在本地开发站点、生产构建和站点搜索索引中。

### 2.2 清理非站点页面

当前根目录中的部分项目说明或模板文件也会被 VitePress 构建为页面：

- `AGENTS.md`
- `README.md`
- `api-examples.md`
- `markdown-examples.md`

处理事项：

- [x] 删除不再使用的 VitePress 示例页：`api-examples.md`、`markdown-examples.md`。
- [x] 将 `AGENTS.md`、`README.md` 保留为仓库文档，但从 VitePress 构建中排除。
- [x] 检查生产构建输出，确认只保留站点需要的页面。

### 2.3 建立文章分类

后续侧边栏建议按以下分类组织：

```text
设计
  HTTP API 设计
  数据库设计

开发
  Java 服务端开发约定
  使用 JPA 访问 JSONB 字段
  Python 入门指南

运维
  Linux 运维操作基础
  Apache Superset 部署
  内网访问与中转

工具
  VSCode Markdown 预览样式
  SVN 到 Git 迁移

归档
  历史环境与实践记录
```

处理事项：

- [ ] 调整 `.vitepress/config.mjs` 的导航和侧边栏分类。
- [ ] 增加文章索引页或让侧边栏承担完整索引职责。
- [ ] 首页 action 保持精简，可指向核心文章或文章索引页。
- [ ] 对外发布前执行 `pnpm build` 验证。

## 3. 优先发布文章

### 3.1 Java 服务端开发约定

路径：

```text
blog/java-server-side-development-conventions/
```

评估：

- 内容结构完整，篇幅和深度适合长期参考。
- 与 HTTP API、PostgreSQL 规范可以形成配套内容。

处理事项：

- [ ] 将 `README.md` 重命名为 `index.md`。
- [ ] 检查 JDK、Spring Boot 相关版本表述，避免过时内容误导读者。
- [ ] 检查图片链接和图片替代文本。
- [ ] 加入“开发”分类侧边栏。

### 3.2 使用 JPA 访问 JSONB 字段

路径：

```text
blog/jpa-json-jsonb/
```

评估：

- 主题明确，与 PostgreSQL 和 Java 开发相关。
- 当前缺少二级标题结构，可读性有提升空间。

处理事项：

- [ ] 将 `README.md` 重命名为 `index.md`。
- [ ] 补充分节结构，例如依赖引入、实体映射、读写示例、查询示例。
- [ ] 核对 Hibernate 5 / Spring Boot 2 与 Spring Boot 3 的写法差异。
- [ ] 加入“开发”分类侧边栏。

### 3.3 Linux 运维操作基础

路径：

```text
blog/linux-ops-basic/
```

评估：

- 已使用 `index.md`，章节结构完整。
- 适合作为运维入门和速查文章。

处理事项：

- [ ] 校对命令在当前常用 Linux 发行版中的适用性。
- [ ] 补充危险命令的注意提示。
- [ ] 加入“运维”分类侧边栏。

### 3.4 在 Kubernetes 中部署 Apache Superset

路径：

```text
blog/deploy-apache-superset-on-k8s/
```

评估：

- 实践过程完整，具备较高发布价值。
- 文中存在 `Dockfile` 拼写错误。
- 文章包含本机 IP，需要替换为示例地址。

已确认保留现状的内容：

- `SUPERSET_SECRET_KEY`
- `superset.db`
- `examples.db`
- `superset_config.py`

处理事项：

- [ ] 修正 `./Dockfile` 为 `./Dockerfile`。
- [ ] 将本机 IP 替换为示例 IP 或域名。
- [ ] 保留现有账号示例和默认账号说明。
- [ ] 将 `README.md` 重命名为 `index.md`。
- [ ] 检查密钥、数据库和配置文件的链接是否仍与保留策略一致。
- [ ] 加入“运维”分类侧边栏。

### 3.5 在 VSCode 预览中使用 GitHub 的中文 Markdown 样式

路径：

```text
blog/github-styled-markdown-preview-for-vscode/
```

评估：

- 问题背景、效果图和配置步骤完整。

处理事项：

- [ ] 将 `README.md` 重命名为 `index.md`。
- [ ] 检查 VSCode 配置路径和样式文件链接。
- [ ] 确认 `sample.pdf` 等附件是否必须随站点发布。
- [ ] 加入“工具”分类侧边栏。

### 3.6 面向非计算机专业研究者的 Python 使用指南

路径：

```text
blog/beginner's-guide-to-python-for-non-computer-researchers/
```

评估：

- 截图和步骤完整，适合入门读者。
- 当前目录名包含 apostrophe，不符合 kebab-case 约定。

处理事项：

- [ ] 将目录重命名为不含特殊字符的 kebab-case 名称。
- [ ] 将 `README.md` 重命名为 `index.md`。
- [ ] 将固定 Python 3.11.2 的表述调整为“示例版本”或更新到当前稳定版本。
- [ ] 检查淘宝镜像链接是否有效。
- [ ] 加入“开发”分类侧边栏。

## 4. 整理后可发布文章

### 4.1 使用中转机从互联网访问内网服务器

路径：

```text
blog/access-intranet-server-from-internet-through-transit-computer/
```

处理事项：

- [ ] 将真实用户名和私网 IP 替换为示例值。
- [ ] 检查 Serveo、ngrok、Pagekite、Portmap 等服务可用性。
- [ ] 补充公网转发、堡垒机、密钥管理和访问审计的安全提示。
- [ ] 将 `README.md` 重命名为 `index.md`。
- [ ] 加入“运维”分类侧边栏。

### 4.2 用 Samba 搭建文件共享服务

路径：

```text
blog/file-share-service-by-samba/
```

评估：

- 当前包含明文密码、人员名、项目名和历史目录树，不适合直接发布。

处理事项：

- [ ] 重写为通用 Samba 配置示例。
- [ ] 删除或替换真实人员名、项目名和目录树。
- [ ] 移除明文密码表，改为创建用户和设置密码的命令示例。
- [ ] 更新 CentOS 7 相关内容或明确标记为历史环境。
- [ ] 将 `README.md` 重命名为 `index.md`。

### 4.3 生产环境自动化部署

路径：

```text
blog/build-devops-environment-in-action/
```

评估：

- 主题有价值，但 Ubuntu 16.04、Docker 17.03、`apt-key` 等内容已经过时。

处理事项：

- [ ] 决定是重写为当前指南，还是作为历史实践归档。
- [ ] 如作为当前指南，更新 Docker 安装和镜像仓库配置。
- [ ] 如作为归档，明确标注适用版本和时间背景。
- [ ] 将 `README.md` 重命名为 `index.md`。

### 4.4 Windows 宿主机与 Ubuntu 虚拟机共享文件夹

路径：

```text
blog/share-folders-between-windows-and-ubuntu-using-open-vm-tools/
```

处理事项：

- [ ] 将 `README.md` 重命名为 `index.md`。
- [ ] 检查 VMware 和 open-vm-tools 的当前建议。
- [ ] 更新失效参考链接。
- [ ] 加入“运维”或“工具”分类侧边栏。

### 4.5 安装 CentOS Minimal 后的注意事项

路径：

```text
blog/notes-about-post-installation-of-centos-minimal/
```

评估：

- CentOS 7 已停止维护，yum 源和软件版本大多失效。

处理事项：

- [ ] 明确标记为历史环境归档，或迁移到当前仍支持的发行版。
- [ ] 检查镜像源和软件源示例。
- [ ] 将 `README.md` 重命名为 `index.md`。

### 4.6 更新 Ubuntu Linux Kernel

路径：

```text
blog/update-ubuntu-kernel/
```

评估：

- 手动升级内核示例停留在 4.x，直接照做风险较高。

处理事项：

- [ ] 重写为当前 Ubuntu 版本下的安全升级建议。
- [ ] 强调保留旧内核和回滚方法。
- [ ] 更新 kernel 包下载地址。
- [ ] 将 `README.md` 重命名为 `index.md`。

### 4.7 为 Windows 控制台应用程序设置默认 CodePage

路径：

```text
blog/set-default-codepage-and-font-for-console-applications-in-chinese-windows/
```

处理事项：

- [ ] 明确适用 Windows 版本范围。
- [ ] 检查注册表脚本和字体附件说明。
- [ ] 评估 7z 附件是否改为压缩包下载或精简。
- [ ] 将 `README.md` 重命名为 `index.md`。

### 4.8 将资料库从 Subversion 迁移到 Git

路径：

```text
blog/repository-migrations-from-subversion-to-git/
```

评估：

- 步骤可操作，但篇幅较短，缺少完整检查和回滚策略。

处理事项：

- [ ] 将 `README.md` 重命名为 `index.md`。
- [ ] 增加迁移前检查清单。
- [ ] 增加迁移结果校验方法。
- [ ] 增加失败处理和回滚说明。
- [ ] 加入“工具”分类侧边栏。

## 5. 移入草稿的文章

以下文章统一移动到 `blog/_drafts/`，并从 VitePress 构建中排除。

### 5.1 Oracle Linux、Database、WebLogic、PSRM 安装实战

路径：

```text
blog/oracle-linux-database-weblogic-psrm-installation-in-action/
```

移入草稿的原因：

- 篇幅巨大，维护成本高。
- 包含大量账号、口令、内部主机名和历史安装路径。
- 强绑定旧版本环境，当前受众价值有限。

处理事项：

- [x] 移动到 `blog/_drafts/oracle-linux-database-weblogic-psrm-installation-in-action/`。
- [x] 确认不再被构建和搜索索引收录。
- [ ] 后续如需公开，必须先拆分系列并全面脱敏。

### 5.2 Shadowsocks 系列

路径：

```text
blog/setup-shadowsocks-server-on-ubuntu/
```

移入草稿的原因：

- 涉及代理、混淆和穿透类工具，存在合规风险。
- 软件和安装方式已经过时。
- 目录中多篇 Markdown 会被单独构建为页面，站点结构较乱。

处理事项：

- [x] 整个目录移动到 `blog/_drafts/setup-shadowsocks-server-on-ubuntu/`。
- [x] 确认不再被构建和搜索索引收录。

### 5.3 REST 风格 HTTP API 设计约定

路径：

```text
blog/http-api-design-conventions-with-rest/
```

移入草稿的原因：

- 与已发布的非 REST API 设计约定高度重复。
- 同时挂在侧边栏容易造成两套规范并存、读者难以选择。

后续可选方案：

- [ ] 合并到现有 HTTP API 文章，形成 REST / 非 REST 对照章节。
- [ ] 或重写为独立文章，明确两者使用边界。

### 5.4 关于 Low-Code Platform

路径：

```text
blog/about-low-code/
```

移入草稿的原因：

- 内容偏观点整理，篇幅较短。
- 引用资料较旧，未覆盖近年 AI 辅助开发与低代码平台变化。

处理事项：

- [x] 移动到 `blog/_drafts/about-low-code/`。
- [ ] 后续结合当前低代码、AI 辅助开发趋势重写。

### 5.5 尝试在 Wine 中运行 .NET WPF 应用程序

路径：

```text
blog/run-dotnet-wpf-application-in-linux-with-wine/
```

移入草稿的原因：

- 实验环境非常旧。
- 记录不完整，缺少明确结论。

处理事项：

- [x] 移动到 `blog/_drafts/run-dotnet-wpf-application-in-linux-with-wine/`。
- [ ] 如后续发布，应标记为历史实验记录并补齐结论。

## 6. 建议执行顺序

### 第一批：站点安全与结构整理

- [x] 增加 `blog/_drafts/` 和 `srcExclude`。
- [x] 将第 5 节列出的文章全部移入草稿。
- [x] 从构建中排除仓库说明文档和 VitePress 示例页。
- [x] 执行构建，确认草稿和无关页面不再输出。

### 第二批：发布核心开发与运维文章

- [ ] Java 服务端开发约定
- [ ] 使用 JPA 访问 JSONB 字段
- [ ] Linux 运维操作基础
- [ ] Apache Superset 部署

### 第三批：发布工具与入门文章

- [ ] VSCode Markdown 预览样式
- [ ] Python 使用指南
- [ ] SVN 到 Git 迁移

### 第四批：逐篇整理后发布

- [ ] 内网访问与中转
- [ ] Samba 文件共享
- [ ] open-vm-tools 共享文件夹
- [ ] CentOS Minimal 历史笔记
- [ ] Ubuntu Kernel 更新
- [ ] Windows CodePage 设置
- [ ] 生产环境自动化部署

## 7. 验收标准

每次内容发布或结构调整后：

- [ ] 使用 Node.js 24 执行构建。
- [ ] 构建成功，无异常退出。
- [ ] 检查首页、导航和侧边栏链接。
- [ ] 检查文章内相对链接和图片。
- [ ] 确认草稿目录未生成页面。
- [ ] 确认仓库说明文档未生成站点页面。
- [ ] 确认没有新增真实密钥、真实账号口令或敏感内部信息。

## 8. 已确认的处理口径

以下为本次评估后确认的执行口径：

1. Apache Superset 文章：
   - `SUPERSET_SECRET_KEY`、`superset.db`、`examples.db`、`superset_config.py` 的保留是有意为之，保持现状。
   - `./Dockfile` 拼写错误需要修正为 `./Dockerfile`。
   - 只需要处理文章中的本机 IP；账号示例保留。

2. Oracle Linux、Database、WebLogic、PSRM 安装实战：
   - 移动到 `_drafts`。
   - 从 VitePress 构建中排除。

3. Shadowsocks 系列：
   - 同意不公开。
   - 移动到 `_drafts` 并从构建中排除。

4. 第 4 节“优先发布文章”：
   - 同意按整理后逐步发布。

5. 第 5 节“整理后可发布文章”：
   - 同意先整理，再评估发布。

6. 第 6 节“移入草稿的文章”：
   - 同意全部进入 `_drafts`。

7. 信息架构调整：
   - 同意按设计、开发、运维、工具、归档等分类重整导航和侧边栏。
