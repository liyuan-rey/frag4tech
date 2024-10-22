import { defineConfig } from "vitepress";

// https://vitepress.dev/reference/site-config
export default defineConfig({
    lang: "zh-CN",
    title: "软件研发技术分享",
    description: "软件研发相关的技术内容分享和示例服务展示。",
    cleanUrls: true,
    lastUpdated: true,
    ignoreDeadLinks: true,
    head: [
        [
            "link",
            {
                rel: "icon",
                href: "/vitepress-logo-mini.svg" 
            }
        ]
    ],
    themeConfig: {
        // https://vitepress.dev/reference/default-theme-config
        logo: "/vitepress-logo-mini.svg",

        nav: [
            { text: "主页", link: "/" },
            {
                text: "设计",
                link: "/blog/http-api-design-conventions-no-rest/",
            },
        ],

        sidebar: [
            {
                text: "设计",
                items: [
                    {
                        text: "HTTP API 设计",
                        link: "/blog/http-api-design-conventions-no-rest/",
                    },
                    {
                        text: "数据库设计",
                        link: "/blog/database-design-develop-guide-for-postgresql/",
                    },
                ],
            },
        ],

        socialLinks: [
            {
                icon: "github",
                link: "https://github.com/liyuan-rey/frag4tech/",
            },
        ],

        footer: {
            message:
                '<a target="_blank" href="http://www.beian.gov.cn/portal/registerSystemInfo?recordcode=42011102005269">鄂公网安备 42011102005269号</a>' +
                ' | <a target="_blank" href="https://beian.miit.gov.cn/">鄂ICP备2023014839号-1</a>',
            copyright:
                '本站基于 <a target="_blank" href="https://github.com/liyuan-rey/frag4tech/blob/master/LICENSE">CC-BY-4.0</a> 授权' +
                ' | Copyright © 2017-present <a target="_blank" href="https://github.com/liyuan-rey/">Li Yuan</a>' +
                '<p>Powered by <a target="_blank" href="https://vitepress.dev/">VitePress</a><p>',
        },
    },
    vite: {
        assetsInclude: ["**/*.PNG"],
    },
});
