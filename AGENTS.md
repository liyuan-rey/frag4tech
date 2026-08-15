# 仓库规范

本仓库是一个 VitePress 技术文档站点，用于记录和分享软件研发相关的文章及配套示例代码。

## 技术栈

- **框架**：VitePress 1.6.x
- **运行时**：Node.js 24.x + Vite
- **版本管理**：fnm 管理 Node.js，版本固定为 24
- **包管理器**：corepack 启用 pnpm 11.x，版本由 `package.json` 中的 `packageManager` 字段固定
- **部署**：Vercel
- **内容格式**：Markdown

## 项目结构

- `index.md`：站点首页。
- `.vitepress/config.mjs`：站点配置、导航、侧边栏和页脚。
- `blog/`：文章目录。每篇文章使用独立子目录，Markdown 正文与图片、示例代码或配置文件放在一起。
- `public/`：静态资源，如 `robots.txt` 和图标。
- `.editorconfig`：统一的编辑器格式约定。
- `.node-version`：本地 Node.js 版本固定为 24。
- `pnpm-workspace.yaml`：pnpm 构建脚本审批等配置。

## 本地环境

使用 fnm 安装并切换 Node.js 24：

```bash
fnm install 24
fnm use 24
corepack enable
corepack prepare pnpm@latest --activate
```

国内环境建议使用 npmmirror 镜像：

```bash
fnm install 24 --node-dist-mirror=https://npmmirror.com/mirrors/node
pnpm config set registry https://registry.npmmirror.com
npm config set registry https://registry.npmmirror.com
```

## 开发与构建命令

请使用 Node.js 24 和 `pnpm` 执行以下命令：

```bash
pnpm install   # 安装依赖
pnpm dev       # 启动本地开发服务器，支持热更新
pnpm build     # 生成生产站点到 dist/
pnpm preview   # 本地预览生产构建结果
```

## 代码风格与命名

格式约定由 `.editorconfig` 控制：

- 代码和配置文件使用 4 个空格缩进，Markdown 使用 2 个空格。
- 使用 UTF-8 编码、LF 换行，并以换行符结尾。
- 文章目录和图片文件名建议使用描述性的 kebab-case。
- 文章内容请使用中文，与现有站点保持一致。

## 测试规范

当前没有自动化测试。合并前请运行 `pnpm build`，确保站点可以正常构建且页面和链接可用。

## Commit 与 Pull Request 规范

提交信息遵循 [Conventional Commits](https://www.conventionalcommits.org/zh-hans/)，建议使用以下类型：

- `feat`：新增功能
- `fix`：修复缺陷
- `docs`：文档更新
- `refactor`：重构
- `chore`：构建或维护性修改

示例：

```text
docs: add superset cloud deployment article
feat: use pnpm with corepack
```

Pull Request 请提交到 `main` 分支，并提供简短描述；涉及布局、图片或站点构建的改动，请在描述中注明已本地执行并通过 `pnpm build`。
