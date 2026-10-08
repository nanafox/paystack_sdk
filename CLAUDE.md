# paystack_sdk: contributor guide for AI assistants

Ruby SDK for the Paystack API. Faraday-based, no Rails dependency.

## The one rule

**Mirror the Paystack API. Never assume.** Before adding or changing any endpoint, validation, error handling or retry behaviour, follow `.claude/skills/paystack-api-workflow/SKILL.md`: read the official docs and spec, record what is verified vs unverified, then build. If sources disagree or can't be read, stop and ask.

## Commands

```sh
bundle exec rspec                 # tests (WebMock is loaded in spec_helper)
bundle exec standardrb            # lint/format (StandardRB, not RuboCop)
bin/paystack-spec audit           # SDK vs Paystack's OpenAPI spec (pinned, offline); must exit 0
bin/paystack-spec update          # refresh the pinned spec from upstream and show what changed
bin/paystack-spec show POST /transfer
bin/paystack-spec missing Customer
```

## Layout

- `lib/paystack_sdk/client.rb`: entry point; resources are memoised accessors on `Client`.
- `lib/paystack_sdk/resources/`: one class per Paystack resource, all `< Base`. Validate input, call `@connection`, wrap with `handle_response`.
- `lib/paystack_sdk/response.rb`: status handling and the dot-notation wrapper. 401, 429 and 5xx raise; other 4xx return an unsuccessful `Response`.
- `lib/paystack_sdk/utils/connection_utils.rb`: Faraday connection: timeouts, `faraday-retry`, transport-error wrapping. Retries are deliberately conservative (see below).
- `lib/paystack_sdk/validations.rb`: input validation raised before any request.

## Conventions

- Style is StandardRB. Run it before committing.
- Public methods get YARD docs with `@param`, `@return`, `@raise` and a `@see` link to the Paystack docs page.
- Specs use connection doubles; assert the exact documented path and payload.
- Retries: reads retry on network errors and 429/502/503/504; writes retry only on 429. Never widen this without verified Paystack behaviour.
- Update `CHANGELOG.md` under `[Unreleased]` and the README for user-visible changes.

## Git and PRs

- Repo is **squash-merge only**; one logical change per PR.
- Do not merge, release or bump the version unless asked.
- Commit messages and PR descriptions carry **no AI attribution** (no "Generated with", no session links, no trailers).
