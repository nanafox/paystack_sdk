import { readFileSync } from "node:fs"
import { dirname, resolve } from "node:path"
import { fileURLToPath } from "node:url"
import { defineConfig } from "vitepress"

const here = dirname(fileURLToPath(import.meta.url))
// Written by scripts/build-content.rb: the version, the base path and the sidebar.
const site = JSON.parse(readFileSync(resolve(here, "../content/site.json"), "utf8"))
const repo = "https://github.com/nanafox/paystack_sdk"

export default defineConfig({
  srcDir: "content",
  title: "paystack_sdk",
  description: "A Ruby client for the Paystack API",
  base: site.base,
  cleanUrls: true,
  lastUpdated: false,
  ignoreDeadLinks: false,
  head: [
    ["meta", { name: "robots", content: site.version === "next" ? "noindex" : "index" }],
    ["link", { rel: "alternate", type: "text/plain", href: `${site.base}llms.txt`, title: "llms.txt" }],
  ],
  themeConfig: {
    siteTitle: `paystack_sdk ${site.version}`,
    nav: [
      { text: "Guides", link: "/guide/introduction" },
      { text: "Reference", link: "/reference/client" },
      { text: "AI skills", link: "/skills/" },
      { text: "Changelog", link: "/changelog" },
    ],
    sidebar: site.sidebar,
    outline: { level: [2, 3], label: "On this page" },
    search: { provider: "local" },
    socialLinks: [{ icon: "github", link: repo }],
    editLink: { pattern: `${repo}/edit/main/README.md`, text: "Edit the README on GitHub" },
    footer: { message: "Released under the MIT License.", copyright: "Every page is also available as raw markdown: see llms.txt." },
  },
})
