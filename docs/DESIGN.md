# Docs design system

The look of the docs site lives in three small files under `.vitepress/theme/`. Change a token and the whole site follows; do not hard-code a colour in a page or a component.

| File | What it holds |
|---|---|
| `tokens.css` | The palette (`--ps-navy-*`, `--ps-green-*`, `--ps-amber-500`), radii, shadow and fonts. The only place a raw colour belongs. |
| `brand.css` | Maps the tokens onto VitePress's `--vp-*` variables for light and dark mode, and styles the shared pieces: callouts, tables, code, navigation. |
| `home.css` | The home page: the navy hero, the code panel, the feature cards and the "For AI agents" band. |

## Colour roles

- **Navy** is structure: the hero, dark-mode backgrounds, headings in light mode.
- **Green** is the one accent: buttons, links, active items, and "confirmed" things. Use it for one thing per view.
- **Amber** is for warnings about money or irreversible actions, via `::: warning`. Nothing else.

## Components

- `HeroPanel.vue`: the code sample on the home page. Everything it shows must exist in the gem; if an API changes, change the sample.
- `VersionSwitcher.vue`: reads `versions.json` at the site root.
- Callouts are VitePress containers: `::: tip` (green), `::: warning` (amber), `::: danger`.
- `static/logo.svg` is the mark (a cut gem with a check) and the favicon. It reads on both light and dark backgrounds.

## Writing

Hand-written pages live in `docs/concepts/`; everything else is generated, so edit the README, a YARD comment or a skill instead. A concept page explains an idea the generated pages assume, and every claim in it must be true of the gem.
