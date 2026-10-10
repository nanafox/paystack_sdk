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
  markdown: { theme: { light: "github-light", dark: "night-owl" } },
  head: [
    ["link", { rel: "icon", type: "image/svg+xml", href: `${site.base}logo.svg` }],
    ["meta", { name: "theme-color", content: "#0b1f3a" }],
    ["meta", { name: "robots", content: site.version === "next" ? "noindex" : "index" }],
    ["link", { rel: "alternate", type: "text/plain", href: `${site.base}llms.txt`, title: "llms.txt" }],
  ],
  themeConfig: {
    logo: "/logo.svg",
    siteTitle: `paystack_sdk ${site.version}`,
    nav: [
      { text: "Guides", link: "/guide/introduction", activeMatch: "/guide/" },
      { text: "Concepts", link: "/concepts/payment-lifecycle", activeMatch: "/concepts/" },
      { text: "Reference", link: "/reference/client", activeMatch: "/reference/" },
      { text: "For AI agents", link: "/skills/", activeMatch: "/skills/" },
      { text: "Changelog", link: "/changelog" },
    ],
    sidebar: site.sidebar,
    outline: { level: [2, 3], label: "On this page" },
    search: { provider: "local" },
    socialLinks: [{ icon: "github", link: repo }],
    editLink: { pattern: `${repo}/edit/main/README.md`, text: "Edit the README on GitHub" },
    footer: {
      message: `paystack_sdk ${site.version} · MIT License · <a href="https://rubygems.org/gems/paystack_sdk" target="_blank" rel="noreferrer">rubygems.org/gems/paystack_sdk</a>`,
      copyright: "Every page is also available as raw markdown: see llms.txt.",
    },
  },
})
