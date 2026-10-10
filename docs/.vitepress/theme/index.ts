import DefaultTheme from "vitepress/theme"
import { h } from "vue"
import VersionSwitcher from "./VersionSwitcher.vue"
import "./custom.css"

export default {
  extends: DefaultTheme,
  Layout() {
    return h(DefaultTheme.Layout, null, {
      "nav-bar-content-after": () => h(VersionSwitcher),
    })
  },
}
