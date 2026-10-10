---
layout: home
title: Paystack Ruby SDK
hero:
  name: paystack_sdk
  text: A Ruby client for the Paystack API
  tagline: Keyword arguments, input validated before anything is sent, and skills that teach AI coding agents to use it safely. Version {{VERSION}}.
  actions:
    - theme: brand
      text: Get started
      link: /guide/installation
    - theme: alt
      text: API reference
      link: /reference/client
    - theme: alt
      text: AI skills
      link: /skills/
features:
  - title: Mirrors Paystack
    details: Every endpoint follows Paystack's documentation, checked in CI against its OpenAPI spec. Where the docs and the spec disagree, the live test API settles it.
  - title: Safe with money
    details: Amounts are integers in the smallest unit, paid? checks amount and currency, writes are never retried after a timeout, and the secret key never shows in inspect output.
  - title: Made for AI agents
    details: Nine skills ship in the gem, and every page here is also available as raw markdown, with llms.txt and llms-full.txt.
---
