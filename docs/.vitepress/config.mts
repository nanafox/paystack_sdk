import { existsSync, readFileSync, statSync } from "node:fs"
import { dirname, resolve } from "node:path"
import { fileURLToPath } from "node:url"
import { defineConfig } from "vitepress"

const here = dirname(fileURLToPath(import.meta.url))
// Written by scripts/build-content.rb: the version, the base path and the sidebar.
const site = JSON.parse(readFileSync(resolve(here, "../content/site.json"), "utf8"))
// `npm run build` copies content-public/ (llms.txt, the raw markdown, the skills) into the site. The dev server
// does not, so serve those files from there too: the same URLs work in `npm run dev`.
const rawFiles = {
  name: "serve-raw-files",
  configureServer(server: any) {
    server.middlewares.use((req: any, res: any, next: () => void) => {
      const path = decodeURIComponent((req.url ?? "").split("?")[0])
      if (!path.startsWith(site.base)) return next()
      // Vite requests the page modules as /skills/index.md (dest "script") and must get those from VitePress;
      // only a direct visit or a plain fetch (curl, an agent) should get the raw file.
      const dest = req.headers["sec-fetch-dest"]
      if (dest && dest !== "document") return next()
      const file = resolve(here, "../content-public", path.slice(site.base.length))
      if (!file.startsWith(resolve(here, "../content-public")) || !existsSync(file) || !statSync(file).isFile()) return next()
      res.setHeader("Content-Type", file.endsWith(".md") || file.endsWith(".txt") ? "text/plain; charset=utf-8" : "application/octet-stream")
      res.end(readFileSync(file))
    })
  },
}

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
  vite: { plugins: [rawFiles] },
  head: [
    ["link", { rel: "icon", type: "image/svg+xml", href: `${site.base}logo.svg` }],
    ["meta", { name: "theme-color", content: "#0b1f3a" }],
    ["meta", { name: "robots", content: site.version === "next" ? "noindex" : "index" }],
    ["link", { rel: "alternate", type: "text/plain", href: `${site.base}llms.txt`, title: "llms.txt" }],
  ],
  themeConfig: {
    logo: "/logo.svg",
    siteTitle: "paystack_sdk",
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
      message: `MIT License · <a href="https://rubygems.org/gems/paystack_sdk" target="_blank" rel="noreferrer">rubygems.org/gems/paystack_sdk</a>`,
      copyright: `© 2026–present Maxwell Nana Forson · every page is also available as raw markdown: see <a href="${site.base}llms.txt">llms.txt</a>`,
    },
  },
})
