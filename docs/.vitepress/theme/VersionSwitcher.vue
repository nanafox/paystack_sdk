<script setup lang="ts">
import { onMounted, ref } from "vue"
import { useData, useRoute } from "vitepress"

// versions.json sits at the root of the site (one level above every version's base) and is written by the
// deploy workflow: { "latest": "0.5.0", "versions": ["0.5.0", "0.4.1"], "next": true }.
const { site } = useData()
const route = useRoute()
const versions = ref<string[]>([])
const current = ref("")
const latestVersion = ref("")
const root = site.value.base.replace(/[^/]+\/$/, "")

onMounted(async () => {
  current.value = site.value.base.slice(root.length).replace(/\/$/, "")
  try {
    const res = await fetch(`${root}versions.json`)
    const data = await res.json()
    latestVersion.value = data.latest
    versions.value = ["latest", ...(data.next ? ["next"] : []), ...data.versions]
    if (!versions.value.includes(current.value)) versions.value.push(current.value)
  } catch {
    versions.value = [current.value]
  }
})

const label = (v: string) => (v === "latest" && latestVersion.value ? `latest (${latestVersion.value})` : v)

function go(event: Event) {
  const target = (event.target as HTMLSelectElement).value
  // Same page in the other version when it exists there, else that version's front page.
  const page = route.path.slice(site.value.base.length - 1)
  const wanted = `${root}${target}${page}`
  fetch(wanted, { method: "HEAD" })
    .then((r) => (window.location.href = r.ok ? wanted : `${root}${target}/`))
    .catch(() => (window.location.href = `${root}${target}/`))
}
</script>

<template>
  <div v-if="versions.length > 1" class="version-switcher">
    <select :value="current" aria-label="Documentation version" @change="go">
      <option v-for="v in versions" :key="v" :value="v">{{ label(v) }}</option>
    </select>
  </div>
</template>
