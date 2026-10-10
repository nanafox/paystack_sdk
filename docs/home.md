---
layout: home
title: Paystack SDK
hero:
  name: Paystack SDK
  text: A Ruby client for the Paystack API
  tagline: Keyword arguments, input checked before anything is sent, and responses that say what actually happened.
  image:
    src: /logo.svg
    alt: Paystack SDK
  actions:
    - theme: brand
      text: Get started
      link: /guide/installation
    - theme: alt
      text: How a payment works
      link: /concepts/payment-lifecycle
    - theme: alt
      text: API reference
      link: /reference/client
features:
  - title: Follows Paystack's docs
    details: Each endpoint is checked in CI against Paystack's OpenAPI spec. Where the docs and the spec disagree, the live test API decides.
  - title: Careful with money
    details: Amounts are integers in the smallest unit. paid? checks amount and currency. A write is never retried after a timeout, and the secret key stays out of inspect output.
  - title: Results you can read
    details: success? means Paystack accepted the call, not that a charge worked. The status and the amount are checked separately, and the docs say which is which.
---

<script setup>
import { withBase } from 'vitepress'
</script>

<div class="ps-band">
  <div>
    <span class="ps-eyebrow">For AI agents</span>
    <h2>Skills your coding agent can load</h2>
    <p>Nine skills ship in the gem and teach an agent the conventions, the flows and the money-safety checks. Every page here is also raw markdown, with <a :href="withBase('/llms.txt')">llms.txt</a> and <a :href="withBase('/llms-full.txt')">llms-full.txt</a>. <a :href="withBase('/skills/')">See the skills</a>.</p>
  </div>
  <pre><code><span class="p">$</span> bundle exec paystack_sdk skills install
<span class="p">$</span> bin/rails generate paystack_sdk:skills</code></pre>
</div>
