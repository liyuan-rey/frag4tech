# Li Yuan's Blog

这是一个基于 VitePress 构建的技术博客，记录软件研发相关的文章和示例代码。

## 技术栈

- VitePress 1.6.x
- Node.js 24.x + Vite
- fnm + corepack + pnpm 11.x
- Vercel

## 本地开发

```bash
fnm install 24
fnm use 24
corepack enable
pnpm install
pnpm dev
```

生产构建使用 `pnpm build`，本地预览生产产物使用 `pnpm preview`。

国内环境可先设置镜像：

```bash
pnpm config set registry https://registry.npmmirror.com
npm config set registry https://registry.npmmirror.com
```

更多贡献规范请参阅 [AGENTS.md](./AGENTS.md)。

站点地址：https://www.getme.guru

---

[CC-BY-4.0](./LICENSE)
