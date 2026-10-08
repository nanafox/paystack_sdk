---
name: paystack-api-workflow
description: 'Use BEFORE adding, changing, fixing or reviewing any endpoint, resource method, validation, error handling or retry behaviour in this SDK. The SDK must mirror the Paystack API exactly: read the official docs and spec first, record what is verified vs unverified, then build. Covers sources, the bin/paystack-spec audit, spec/test rules and the PR checklist.'
---

# Paystack API workflow (docs first, always)

This gem is an SDK. Its only job is to match the Paystack API. An endpoint built from memory, from another SDK or from a blog post is a bug waiting to ship: `Customers#deactivate_authorization` posted to a path Paystack never documented, and its spec passed because the spec mocked the same wrong path.

## Rules

1. **Never assume Paystack behaviour.** Paths, methods, required fields, enums, headers, status codes, rate limits, idempotency, retry safety: read it, don't recall it.
2. **Unverified means unverified.** If you cannot confirm something, say so in the PR and take the conservative option. Money-moving endpoints (transfers, charges, refunds) are never retried or "reconciled" on a guess.
3. **If sources disagree, or none is reachable, stop and ask the maintainer.** Do not pick one silently.

## Sources, in order of authority

| Source | Use for | Notes |
|---|---|---|
| https://paystack.com/docs/api/ | Canonical docs: behaviour, flows, errors | Returns 403 to bots. Ask the maintainer to check a page when needed. |
| https://github.com/PaystackOSS/openapi (`dist/paystack.yaml`) | Paths, methods, required fields, enums | Official, MIT. Read it with `bin/paystack-spec`. May lag the docs. |
| `https://docs-v2.production.paystack.co/docs/api/<resource>/` and `/llms.txt` | Fetchable copy of the docs | HTML is JS-heavy: strip `<style>`/`<script>` before reading. State in the PR that you used the copy. |

Never treat third-party posts, other SDKs or blog articles as evidence. They can point you to something to check, nothing more.

## Workflow for an endpoint (new or changed)

1. **Find it in the spec.**
   ```sh
   bin/paystack-spec missing Transfer          # what is not implemented for a tag
   bin/paystack-spec show POST /transfer       # method, path, required fields (*), enums, descriptions
   ```
   Required fields can live in a base schema (`allOf`); `show` flattens them. Do not read the YAML by eye.
2. **Read the docs page** for the same operation. Note what the spec does not tell you: statuses returned, OTP/PIN/redirect flows, currency/country limits, rate-limit or idempotency notes.
3. **Write down the facts** (in the PR draft before coding): the exact `METHOD /path`, required vs optional fields, enums, and a list of anything you could not confirm.
4. **Implement** in `lib/paystack_sdk/resources/`:
   - Use the documented path exactly, with a leading `/`.
   - Validate required fields exactly as documented. Don't invent stricter rules (and don't drop documented ones). Enums come from the spec.
   - Add `@see https://paystack.com/docs/api/<resource>/#<anchor>` to the method.
   - Keep to the repo's error model: validation errors raise before any request; 4xx (except 401/429) come back as unsuccessful `Response`; 401, 429, 5xx and transport failures raise.
5. **Spec it so it can't hide the same bug.**
   - Assert the exact documented path and body in the connection double.
   - Cover each required field missing, and each enum/format rule you added.
   - Mocks only prove the code does what the spec says. The audit proves the code matches Paystack.
6. **Run the audit; it must exit 0.**
   ```sh
   bin/paystack-spec audit    # lists SDK calls with no matching spec operation; exit 1 if any
   bundle exec rspec && bundle exec standardrb
   ```
7. **Open the PR** with a *Verification* section (see below), a CHANGELOG entry under `[Unreleased]`, and README updates if user-visible.

## Facts already verified (with source)

- Amounts are in the subunit (kobo, pesewas, cents). XOF has no subunit, multiply by 100. (Paystack `llms.txt`)
- Rate limiting returns `429` with `x-ratelimit-reset`, `x-ratelimit-remaining`, `x-ratelimit-limit`. There is no documented `Retry-After`. (docs: rate-limits page)
- `POST /transfer` requires `amount`, `recipient`, `reference`, `source`. `reference` is documented as "to ensure idempotency… a unique identifier". (OpenAPI `TransferBase` + `TransferInitiate`)
- Deactivate an authorization: `POST /customer/authorization/deactivate`, body `authorization_code`. (docs + OpenAPI)

## Still unverified (do not rely on these)

- What Paystack returns when a `reference` is reused on transfers or charges (existing record vs error).
- Whether `x-ratelimit-reset` is seconds-from-now or an epoch value on a real 429.
- That a 429 means the request was not processed.
- Which statuses (beyond 429) are safe to retry on writes.

Update this list when something is confirmed, and cite the source.

## PR checklist

- [ ] Each endpoint touched: spec entry and docs page read (state which source you actually read).
- [ ] *Verification* section lists the exact `METHOD /path`, required fields and sources, and lists unverified items separately.
- [ ] Specs assert the documented path and payload.
- [ ] `bin/paystack-spec audit` exits 0.
- [ ] CHANGELOG `[Unreleased]` entry; README updated for user-visible changes.
- [ ] Squash-merge friendly: one logical change per PR. No AI attribution in commits or PR text.
