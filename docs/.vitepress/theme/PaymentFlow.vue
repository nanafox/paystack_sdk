<script setup lang="ts">
// The payment cycle as a picture. Three actors, five steps; the colour says who is speaking and whether
// it can be trusted. Keep it in step with concepts/01-payment-lifecycle.md.
const steps = [
  { n: 1, who: "you", title: "Record it", note: "Save a pending payment with a new reference, before calling Paystack." },
  { n: 2, who: "you", title: "Start it", note: "initiate, then send the payer to authorization_url." },
  { n: 3, who: "payer", title: "They pay, then return", note: "The redirect only says \"please check\". It is not proof.", weak: true },
  { n: 4, who: "paystack", title: "Ask Paystack", note: "verify by reference, then paid?(amount:, currency:).", strong: true },
  { n: 5, who: "paystack", title: "Webhook says the same", note: "charge.success runs the same confirmation, safely twice.", strong: true },
]
const lanes: Record<string, string> = { you: "Your server", payer: "The payer", paystack: "Paystack" }
</script>

<template>
  <figure class="flow" aria-label="The five steps of a payment">
    <ol class="flow-steps">
      <li v-for="s in steps" :key="s.n" class="flow-step" :class="[`who-${s.who}`, { weak: s.weak, strong: s.strong }]">
        <span class="flow-badge">{{ s.n }}</span>
        <span class="flow-who">{{ lanes[s.who] }}</span>
        <strong class="flow-title">{{ s.title }}</strong>
        <span class="flow-note">{{ s.note }}</span>
      </li>
    </ol>
    <figcaption class="flow-legend">
      <span><i class="dot weak" /> not proof</span>
      <span><i class="dot strong" /> trusted: it comes from Paystack, checked by reference</span>
    </figcaption>
  </figure>
</template>

<style scoped>
.flow { margin: 28px 0; }
.flow-steps {
  display: grid;
  grid-template-columns: repeat(5, minmax(0, 1fr));
  gap: 0;
  margin: 0;
  padding: 0;
  list-style: none;
  counter-reset: none;
}
.flow-step {
  position: relative;
  display: flex;
  flex-direction: column;
  gap: 6px;
  margin: 0 !important;
  padding: 16px 14px 16px;
  border: 1px solid var(--vp-c-divider);
  border-left-width: 0;
  background: var(--vp-c-bg-soft);
  font-size: 13px;
  line-height: 1.5;
}
.flow-step:first-child { border-left-width: 1px; border-radius: 12px 0 0 12px; }
.flow-step:last-child { border-radius: 0 12px 12px 0; }
/* the arrow into the next step */
.flow-step:not(:last-child)::after {
  content: "";
  position: absolute;
  top: 50%;
  right: -7px;
  z-index: 1;
  width: 12px;
  height: 12px;
  background: var(--vp-c-bg);
  border-top: 1px solid var(--vp-c-divider);
  border-right: 1px solid var(--vp-c-divider);
  transform: translateY(-50%) rotate(45deg);
}
.flow-badge {
  display: inline-grid;
  place-items: center;
  width: 26px;
  height: 26px;
  border-radius: 50%;
  background: var(--ps-navy-900);
  color: #fff;
  font: 700 13px var(--ps-font-sans);
}
.flow-who {
  font: 600 11px var(--ps-font-mono);
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--vp-c-text-2);
}
.flow-title { color: var(--vp-c-text-1); font-size: 15px; letter-spacing: -0.01em; }
.flow-note { color: var(--vp-c-text-2); }

.flow-step.strong {
  background: color-mix(in srgb, var(--ps-green-500) 10%, var(--vp-c-bg-soft));
  border-color: color-mix(in srgb, var(--ps-green-500) 45%, var(--vp-c-divider));
}
.flow-step.strong .flow-badge { background: var(--ps-green-500); color: var(--ps-navy-950); }
.flow-step.weak {
  background: color-mix(in srgb, var(--ps-amber-500) 9%, var(--vp-c-bg-soft));
  border-style: dashed;
}
.flow-step.weak .flow-badge { background: var(--ps-amber-500); color: var(--ps-navy-950); }

.flow-legend {
  display: flex;
  flex-wrap: wrap;
  gap: 8px 22px;
  margin-top: 12px;
  font-size: 12.5px;
  color: var(--vp-c-text-2);
}
.dot { display: inline-block; width: 9px; height: 9px; margin-right: 6px; border-radius: 50%; }
.dot.weak { background: var(--ps-amber-500); }
.dot.strong { background: var(--ps-green-500); }

@media (max-width: 860px) {
  .flow-steps { grid-template-columns: 1fr; }
  .flow-step { border-left-width: 1px; border-top-width: 0; padding-left: 52px; }
  .flow-step:first-child { border-top-width: 1px; border-radius: 12px 12px 0 0; }
  .flow-step:last-child { border-radius: 0 0 12px 12px; }
  .flow-badge { position: absolute; left: 14px; top: 14px; }
  .flow-step:not(:last-child)::after { top: auto; bottom: -7px; right: auto; left: 26px; transform: rotate(135deg); }
}
</style>
