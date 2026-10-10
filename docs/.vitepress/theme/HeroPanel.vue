<script setup lang="ts">
// The code on the home page. It is shown, not run: every call and keyword here exists in the gem
// (transactions.initiate, authorization_url, transactions.verify, paid?(amount:, currency:)).
</script>

<template>
  <div class="ps-panel" aria-label="Example: start a payment, then confirm it">
    <div class="ps-panel-bar"><span>payments_controller.rb</span></div>
<pre><code><span class="k">client</span> = PaystackSdk::Client.new

<span class="c"># 1. start the payment, send the payer to Paystack</span>
res = client.transactions.initiate(
  <span class="k">email:</span> <span class="s">"ama@example.com"</span>, <span class="k">amount:</span> <span class="n">5000</span>,
  <span class="k">currency:</span> <span class="s">"GHS"</span>, <span class="k">reference:</span> <span class="s">"pay-8f2c"</span>
)
redirect_to res.authorization_url

<span class="c"># 2. on the callback or webhook: ask Paystack, not the browser</span>
res = client.transactions.verify(<span class="k">reference:</span> <span class="s">"pay-8f2c"</span>)
<span class="ok">grant_access</span> if res.paid?(<span class="k">amount:</span> <span class="n">5000</span>, <span class="k">currency:</span> <span class="s">"GHS"</span>)</code></pre>
  </div>
</template>
