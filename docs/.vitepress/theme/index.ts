import DefaultTheme from "vitepress/theme"
import { h } from "vue"
import HeroPanel from "./HeroPanel.vue"
import VersionSwitcher from "./VersionSwitcher.vue"
import "./tokens.css"
import "./brand.css"
import "./home.css"

export default {
  extends: DefaultTheme,
  Layout() {
    return h(DefaultTheme.Layout, null, {
      "nav-bar-content-after": () => h(VersionSwitcher),
      "home-hero-image": () => h(HeroPanel),
    })
  },
}
