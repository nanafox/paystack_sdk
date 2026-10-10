---
layout: home
title: Paystack Ruby SDK
hero:
  name: paystack_sdk
  text: Take payments in Ruby without guessing.
  tagline: A Ruby client for the Paystack API. Keyword arguments, input checked before anything is sent, and results you can trust with money.
  image:
    src: /logo.svg
    alt: paystack_sdk
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
  - title: Mirrors Paystack
    details: Every endpoint follows Paystack's documentation and is checked in CI against its OpenAPI spec. Where the two disagree, the live test API settles it.
  - title: Safe with money
    details: Amounts are integers in the smallest unit, paid? checks amount and currency, writes are never retried after a timeout, and the secret key stays out of inspect output.
  - title: Honest about results
    details: success? means Paystack accepted the call, not that a charge worked. The docs say so on every page that matters, and so does the code.
---

<div class="ps-band">
  <div>
    <span class="ps-eyebrow">For AI agents</span>
    <h2>Skills your coding agent can load</h2>
    <p>Nine skills ship in the gem and teach an agent the conventions, the flows and the money-safety checks. Every page here is also raw markdown, with <a href="llms.txt">llms.txt</a> and <a href="llms-full.txt">llms-full.txt</a>. <a href="skills/">See the skills</a>.</p>
  </div>
  <pre><code><span class="p">$</span> bundle exec paystack_sdk skills install
<span class="p">$</span> bin/rails generate paystack_sdk:skills</code></pre>
</div>
