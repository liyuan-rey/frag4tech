import { defineConfig } from 'vitepress'

// https://vitepress.dev/reference/site-config
export default defineConfig({
  lang: 'zh-CN',
  head: [['link', { rel: 'icon', href: '/vitepress-logo-mini.svg' }]],
  title: "软件开发技术分享",
  description: "软件开发相关的技术内容分享和示例服务展示。",
  lastUpdated: true,
  themeConfig: {
    // https://vitepress.dev/reference/default-theme-config
    logo: '/vitepress-logo-mini.svg',

    nav: [
      { text: '主页', link: '/' },
      { text: '设计', link: '/http-api-design-conventions-no-rest' }
    ],

    sidebar: [
      {
        text: '设计',
        items: [
          { text: 'HTTP API 设计', link: '/http-api-design-conventions-no-rest' },
          { text: '数据库设计', link: '/database-design-develop-guide-for-postgresql' }
        ]
      }
    ],

    socialLinks: [
      { icon: 'github', link: 'https://github.com/liyuan-rey/frag4tech/gh-pages' }
    ],

    footer: {
      message: '本站基于 <a href="https://github.com/liyuan-rey/frag4tech/blob/master/LICENSE">CC-BY-4.0</a> 授权' + 
        ' | <a href="https://beian.miit.gov.cn" target="_blank">鄂ICP备2023014839号-1</a>' + 
        ' | Powered by <a href="https://vitepress.dev" target="_blank">VitePress</a>',
      copyright: 'Copyright © 2017-present <a href="https://github.com/liyuan-rey">Li Yuan</a>'
    }
  }
})
