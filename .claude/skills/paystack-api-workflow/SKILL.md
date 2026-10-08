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
| https://github.com/PaystackOSS/openapi (`dist/paystack.yaml`) | Paths, methods, required fields, enums | Official, MIT. Read it with `bin/paystack-spec`. Pinned in `spec/fixtures/` (refresh deliberately with `bin/paystack-spec update`). It can disagree with the docs on query parameter names. |
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
   - Send a **real request** through `PaystackSdk::Client` with WebMock (`stub_request(:post, "https://api.paystack.co/...")`), not a connection double. `spec/support/paystack_contract.rb` then checks every request to api.paystack.co against the pinned OpenAPI spec (operation, query names, body fields, types, enums, formats, required fields, bearer auth) and fails the example if it does not conform. Doubles only prove the code does what the code does.
   - Assert the exact path and body too, and cover each required field missing and each rule you added.
   - Where the canonical docs and the spec disagree on a name, follow the docs and record it, with its docs URL and when it was confirmed, in `spec/support/paystack_contract_exceptions.yml`. Never add an exception from the spec or the mirror alone.
   - Opt out with `contract: false` only for specs that send odd requests on purpose (transport tests), with a comment saying why.
6. **Run the audit; it must exit 0.**
   ```sh
   bin/paystack-spec audit    # lists SDK calls with no matching spec operation; exit 1 if any (CI runs it offline)
   bundle exec rspec && bundle exec standardrb
   ```
7. **Open the PR** with a *Verification* section (see below), a CHANGELOG entry under `[Unreleased]`, and README updates if user-visible.

## Conventions for endpoint methods

The SDK is idiomatic and opinionated in Ruby and exact on the wire.

- **Keywords for every parameter.** Path parameters first, then required ones, then optional ones with `nil` defaults. Declaring them explicitly means Ruby rejects a typo (`referance:`) instead of silently sending nothing.
- **snake_case in Ruby, Paystack's names on the wire.** `per_page:` is sent as `perPage` where the docs say so. The mapping lives in one `WIRE_NAMES` constant per resource, applied by `to_wire`. Keywords that clash with Ruby (`next`) get a suffix (`next_cursor`).
- **Names follow the canonical docs, not the spec,** when the two disagree. Record the difference in `spec/support/paystack_contract_exceptions.yml` (set `ruby:` when the idiomatic keyword is not the snake_case of the wire name).
- **Helpers** (`RequestHelpers`, all private): `escape_path` for every path segment (it also refuses `.`, `..` and empty values, which the URL builder would resolve to a different endpoint), `to_wire` to rename and drop nils, `format_datetime` / `format_date` for Date, Time or ISO strings, `stringify_json` for fields the spec calls "stringified JSON".
- **Validate** required values with `validate_presence!` and spec enums with `validate_allowed_values!`. Do not invent rules the spec and docs do not state.
- **Bodies.** POST/PUT send a JSON body; a few DELETEs do too (`request.body =`); one endpoint takes a JSON array.
- **Method names** are the operation's verb without the resource noun: `create`, `list`, `fetch`, `update`, `verify`, `submit_otp`.
- **Always document** with `@param` types, `@return`, `@raise` and a `@see` link to the canonical docs anchor.

## Starting a resource: `bin/paystack-scaffold`

```sh
bin/paystack-scaffold --tags                    # the 27 tags and their operation counts
bin/paystack-scaffold Refund --dry-run          # say what would be created; write nothing
bin/paystack-scaffold Refund                    # create the class, its specs and the Client wiring
bin/paystack-scaffold Refund --destroy          # undo it (add --dry-run to preview)
bin/paystack-scaffold Refund --print            # print the class instead (--print --spec: the specs)
```

It creates `lib/paystack_sdk/resources/<name>.rb` and `spec/resources/<name>_spec.rb`, adds the `require` and the `client.<name>` accessor to `Client`, and reports each step Rails style (`create`, `insert`, `identical`, `update`, `conflict`, `force`, `remove`, `skip`, `protected`). It is safe to run twice.

**Generated files are marked and signed.** Each starts with a "Generated by bin/paystack-scaffold" comment and a `scaffold-digest` of the rest of the file. A file that still matches its digest is the scaffold's to regenerate (`update`) or remove, even when it is committed, so a spec bump can be re-applied without `--force`. Edit a generated file by hand and the digest no longer matches: it becomes yours and is protected.

**Hand-written extras go in `lib/paystack_sdk/resources/extensions/<name>.rb`** (a module `PaystackSdk::Resources::Extensions::<Class>`). The generated class includes it when it exists, so regenerating never loses it.

**Method names** come from the operation's summary unless `bin/scaffold_names.yml` names the operation (keyed `"METHOD /path"`). That file keeps the names the SDK has always used (`initiate`, `totals`, `timeline`, `create`). The scaffold refuses a name that would shadow Ruby's own methods or the base class's (`initialize`, `send`, `format`...) and says to add it there.

**Checks it adds on its own,** matching what the SDK has always done: `validate_email!` for `email`, `validate_positive_integer!` for `amount`, `page` and `per_page`, and `validate_reference_format!` for a `reference` you send (skipped when optional and nil; never applied to a reference in the path). Enums come from the spec.

**It protects your work.** A file that git tracks and the scaffold did not write (or that someone edited) is **never** overwritten or removed, even with `--force` (`protected`): use `git rm` / `git mv` yourself if you mean to replace it. An *untracked* file you edited needs `--force`, is copied to `tmp/scaffold-backups/<timestamp>/` first (gitignored), and the report says how many lines it replaced or removed. Any conflict leaves `Client` untouched, and a hand-written `client.<name>` accessor (and its `require`) is never removed. Use `--dry-run` first. `--skip-spec` leaves the specs out.

The generated specs send real requests through the contract checker, so they prove the request conforms to the spec. Its output is already StandardRB-clean, with long signatures wrapped one keyword per line and the wire hash built in a named local.

**Treat everything it writes as a draft:** read each operation on the canonical docs page, then fix method names, descriptions (Paystack's spec has copy-paste errors, e.g. `percentage_charge` is described as "Customer's phone number"), enum and format rules the docs add, and any docs-versus-spec name differences. Then add a README section and a CHANGELOG entry, and run `bundle exec rspec`, `bundle exec standardrb` and `bin/paystack-spec audit`.

## Facts already verified (with source)

- Amounts are in the subunit (kobo, pesewas, cents). XOF has no subunit, multiply by 100. (Paystack `llms.txt`)
- Rate limiting returns `429` with `x-ratelimit-reset`, `x-ratelimit-remaining`, `x-ratelimit-limit`. There is no documented `Retry-After`. (docs: rate-limits page)
- `POST /transfer` requires `amount`, `recipient`, `reference`, `source`. `reference` is documented as "to ensure idempotency… a unique identifier". (OpenAPI `TransferBase` + `TransferInitiate`)
- Deactivate an authorization: `POST /customer/authorization/deactivate`, body `authorization_code`. (docs + OpenAPI)

- Webhooks: events carry `x-paystack-signature`, a lowercase hex HMAC SHA512 of the raw body using the secret key; verify it before processing. Paystack sends only from `52.31.139.75`, `52.49.173.169`, `52.214.14.220` (test and live). Unacknowledged events are retried: live every 3 minutes for 4 tries then hourly for 72 hours, test hourly for 10 hours, 30-second timeout. The body is `{"event": "...", "data": {...}}`. (docs: payments/webhooks page)

## Still unverified (do not rely on these)

- What Paystack returns when a `reference` is reused on transfers or charges (existing record vs error).
- Whether `x-ratelimit-reset` is seconds-from-now or an epoch value on a real 429.
- That a 429 means the request was not processed.
- Which statuses (beyond 429) are safe to retry on writes.
- Whether webhook payloads carry a unique event id for de-duplication (the docs do not show one), and the exact `data` shape of each event (only one example is visible in the mirrored page).

Update this list when something is confirmed, and cite the source.

## PR checklist

- [ ] Each endpoint touched: spec entry and docs page read (state which source you actually read).
- [ ] *Verification* section lists the exact `METHOD /path`, required fields and sources, and lists unverified items separately.
- [ ] Specs assert the documented path and payload.
- [ ] `bin/paystack-spec audit` exits 0.
- [ ] CHANGELOG `[Unreleased]` entry; README updated for user-visible changes.
- [ ] Squash-merge friendly: one logical change per PR. No AI attribution in commits or PR text.
