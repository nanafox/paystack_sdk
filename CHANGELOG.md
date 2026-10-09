# Changelog

## [Unreleased]

## [0.3.0] - 2026-10-09

### Added

- `client.splits` for Paystack's Transaction Splits API: `create`, `list`, `fetch`, `update`, `add_subaccount` (also updates an existing subaccount's share) and `remove_subaccount`, generated from the OpenAPI spec. `list` sends `perPage` (the API ignores the spec's `per_page`); `fetch` takes a split code or numeric ID; `add_subaccount` requires `subaccount` and `share`, and `remove_subaccount` requires `subaccount`, as the docs and test API do.
- `disputes` (new, generated from Paystack's OpenAPI spec): `list`, `fetch`, `list_transaction`, `update`, `add_evidence`, `fetch_upload_url`, `resolve` and `export`. `fetch_upload_url` takes `upload_filename`, which Paystack documents and the test API honours although the OpenAPI spec omits it.
- `Subaccounts` (`client.subaccounts`): `create`, `list`, `fetch(id_or_code:)` and `update(id_or_code:, ...)`, generated from Paystack's OpenAPI spec. The bank is sent as `bank_code`, as Paystack's docs name it (the spec says `settlement_bank`; the test API reads both and prefers `bank_code`). `list(active:)` takes `1` or `0`: Paystack reads `true` as inactive.
- `Plans` (`client.plans`): `create`, `list`, `fetch(id_or_code:)` and `update(id_or_code:, ...)`, generated from Paystack's OpenAPI spec. `interval` accepts `hourly` and `quarterly` as well as the spec's five values (the test API accepts all seven; the spec omits two). `update` takes `update_existing_subscriptions`, which Paystack documents and the test API validates although the spec omits it; leave it out and Paystack applies the change to existing subscriptions. `list(status:)` is documented by Paystack but absent from the spec.
- `settlements` (new): `list(per_page:, page:, from:, to:)` for `GET /settlement` and `transactions(id:)` for `GET /settlement/{id}/transactions`. `from` and `to` are in Paystack's docs but not the spec; the test API validates them.
- `Balances` (`client.balances`): `fetch` and `ledger(per_page:, page:, from:, to:)`, generated from Paystack's OpenAPI spec and read-only (GET). `fetch` returns one entry per currency with the balance in the currency's subunit (pesewas for GHS). Paystack's docs have no Balance page; the two operations sit on the Transfers Control page and the behaviour was confirmed against the test API.
- `Subscriptions` (`client.subscriptions`): `create`, `list`, `fetch(id_or_code:)`, `enable(code:, token:)`, `disable(code:, token:)`, `generate_update_link(code:)` and `send_update_link(code:)`, generated from Paystack's OpenAPI spec. `list` filters by `plan_id:` and `customer_id:` (sent as `plan` and `customer`): the test API matches numeric IDs only. `start_date` is checked as ISO 8601 before sending, since the test API refuses an invalid one but still creates the subscription.
- `DedicatedVirtualAccounts` (`client.dedicated_virtual_accounts`), generated from Paystack's OpenAPI spec: `create`, `assign`, `list`, `fetch(dedicated_account_id:)`, `requery`, `deactivate(dedicated_account_id:)`, `add_split`, `remove_split` and `fetch_bank_providers`.
- `PaymentRequests` (`client.payment_requests`), generated from Paystack's OpenAPI spec: `create`, `list`, `fetch(id_or_code:)`, `update(id_or_code:)`, `verify(code:)`, `notify(code:)`, `totals`, `finalize(id_or_code:, send_notification: nil)` and `archive(id_or_code:)`. Checked against the Paystack test API, `create` does not require `amount` when `line_items` or `tax` are given (the spec says it is required), takes `metadata` as a Hash and `redirect_url` (both docs-only), and accepts a date as `due_date`; `list` filters by the numeric `customer_id:` and takes `include_archive:`.
- `bin/paystack-scaffold` applies `required: true` from body-field entries in `spec/support/paystack_contract_exceptions.yml`, as it already did for query parameters.
- `bin/paystack-scaffold` applies `enum:` from body-field entries in `spec/support/paystack_contract_exceptions.yml`, as it already did for query parameters.

### Fixed

- `bin/paystack-scaffold` now adds a resource's `Client` accessor above `Client`'s private helpers, where it is public, instead of at the end of the class. It also finds the docs anchor of an operation whose cURL sample on the docs page calls another path (Split Dedicated Account Transaction), and corrects the `@see` link of `customers.direct_debit_activation_charge` to `#directdebit-activation-charge`.

## [0.2.0] - 2026-10-09

### Breaking

- `Transactions` is now generated from Paystack's OpenAPI spec and takes keyword arguments instead of payload hashes. Method names are unchanged.
  - `initiate(email:, amount:, ...)`, `charge_authorization(email:, amount:, authorization_code:, ...)` and `partial_debit(email:, amount:, authorization_code:, currency:, ...)` no longer accept a hash; use `initiate(**params)` to migrate.
  - `fetch(id:)` replaces `fetch(transaction_id)`; `timeline(id:)` replaces `timeline(id_or_reference)`.
  - `list`, `totals` and `export` take named filters (`from`, `to`, `status`, `customer_id`, `settlement`, ...) instead of `**params`, so a misspelt filter now raises `ArgumentError`. `list` no longer defaults `per_page: 50, page: 1`; Paystack's own defaults apply.
  - The numeric customer filter on `list` and `export` is `customer_id:` (it sends Paystack's `customer`).
- `Charges` is now generated from Paystack's OpenAPI spec and takes keyword arguments instead of payload hashes.
  - `mobile_money(email:, amount:, mobile_money:, currency: nil, reference: nil, metadata: nil)` no longer accepts a hash; use `mobile_money(**params)` to migrate. It no longer sends `callback_url`, which neither Paystack's docs nor its spec list for `POST /charge` (the API does not validate it either).
  - `submit_otp(otp:, reference:)` no longer accepts a hash.

- `Banks` is regenerated from Paystack's OpenAPI spec, `Miscellaneous` is new, and `Verification` (`client.verification`) is removed. All take keyword arguments.
  - `verification.resolve_account(account_number:, bank_code:)` is now `banks.resolve_account_number(account_number:, bank_code:)`.
  - `verification.validate_account(hash)` is now `banks.validate_account(account_name:, account_number:, account_type:, bank_code:, country_code:, document_type:, document_number: nil)`.
  - `verification.resolve_card_bin(bin)` is now `miscellaneous.resolve_card_bin(bin:)`. New: `miscellaneous.list_countries` and `miscellaneous.list_states(country:)`.
  - `banks.list` takes named filters instead of a hash (`per_page:` is sent as `perPage`, `next_cursor:` as `next`) and now accepts every filter Paystack documents (`country`, `type`, `gateway`, `use_cursor`, ...). Its `type` enum uses `ghipss` (the spec's `ghipps` is a typo), and `currency` still accepts `USD`.
- `TransferRecipients` is now generated from Paystack's OpenAPI spec and takes keyword arguments instead of payload hashes. Method names are unchanged.
  - `create(type:, name:, account_number:, bank_code:, ...)` no longer accepts a hash; use `create(**params)` to migrate. `type` is checked against Paystack's list (`nuban`, `ghipss`, `mobile_money`, `basa`, `authorization`).
  - `fetch(id_or_code:)`, `update(id_or_code:, name:, email:)` and `delete(id_or_code:)` replace `recipient_code:`. The value can be the recipient code or its numeric ID. `update` takes `name:` and `email:` instead of a `params:` hash; `name` is optional, as the API accepts an update with only `email` (docs say `name` is required; checked against the test API).
  - `list` takes `per_page:`, `page:`, `use_cursor:`, `next_cursor:` and `previous:` instead of a query hash. `perPage` is what Paystack's docs name the page size; the API honours it. `from` and `to` are in the docs but the API ignores them, so they are not offered.
- `Customers` is now generated from Paystack's OpenAPI spec and takes keyword arguments instead of payload hashes. Method names are unchanged.
  - `create(email:, ...)`, `set_risk_action(customer:, risk_action: nil)` and `deactivate_authorization(authorization_code:)` no longer accept a hash; use `create(**params)` to migrate.
  - `fetch(email_or_code:)` replaces `fetch(email_or_code)` (the keyword is the path variable's name in Paystack's docs; it takes an email or a customer code); `update(code:, first_name: nil, ...)` replaces `update(code, payload)`; `validate(code:, ...)` replaces `validate(code, payload)`.
  - `validate` now requires `first_name`, `last_name`, `type`, `country`, `bvn`, `bank_code` and `account_number`, as Paystack does (the test API answers 400 without each). It previously did not require `bvn` or the names.
  - `list` takes named filters (`per_page`, `page`, `from`, `to`, `use_cursor`, `next_cursor`, `previous`) instead of `**params`, and no longer defaults `per_page: 50, page: 1`; Paystack's own defaults apply.
  - `metadata` on `create` and `update` must be a Hash; it is sent as a JSON object (Paystack rejects a JSON string).
- `Transfers` is now generated from Paystack's OpenAPI spec and takes keyword arguments instead of payload hashes. Existing method names are unchanged.
  - `create(source:, amount:, recipient:, reference:, reason: nil, currency: nil)` no longer accepts a hash; use `create(**params)` to migrate. `reference` is now required, as Paystack's docs and spec both require it, and `currency` must be one of NGN, ZAR, KES, GHS.
  - `fetch(id_or_code:)` replaces `fetch(id:)`, using the docs' name for the path variable (it takes a transfer ID or a `TRF_` code). The request is unchanged.
  - `list` takes named filters (`per_page`, `page`, `from`, `to`, `recipient`, `status`, and cursor pagination with `use_cursor`, `next_cursor`, `previous`) instead of a query hash, so a misspelt filter now raises `ArgumentError`. `per_page` is sent as `perPage`.

### Fixed

- Values placed in URL paths (references, codes, ids, card BINs) are now escaped, and `.` / `..` are refused with `PaystackSdk::InvalidValueError` before any request is sent. Previously a value such as `".."` was resolved by the URL builder into a different endpoint (`transactions.verify(reference: "..")` called `/transaction`), and `/`, `?` or `#` in a value changed the path or query. Affects `transactions` (`verify`, `fetch`, `timeline`), `transfers` (`fetch`, `verify`), `transfer_recipients` (`fetch`, `update`, `delete`), `customers` (`fetch`, `update`, `validate`) and `miscellaneous` (`resolve_card_bin`).
- `Response#[]` and `Response#key?` returned `nil`/`false` for every key on real Paystack bodies (string keys). Both now accept strings or symbols.
- `Customers#deactivate_authorization` called a non-existent endpoint (`customer/deactivate_authorization`). It now posts to Paystack's documented `POST /customer/authorization/deactivate`.
- `429` responses now raise `RateLimitError` (previously swallowed as a client error because the `400..499` branch matched first). `retry_after` is read from Paystack's `x-ratelimit-reset` header (nil when absent) instead of the undocumented `Retry-After`.

### Added

- `Client#live?` and `Client.new(..., sandbox_only: true)`: the client refuses to be built with anything but an `sk_test_` key (or a pre-built connection that sends one), raising `ArgumentError` before any request.
- `Response#paid?(amount: nil, currency: nil)` (call succeeded, `status` is `"success"`, and the amount and currency match if given) and `Response#status?(value)`.
- `spec/sandbox/`: specs against Paystack's real test API, skipped unless `PAYSTACK_TEST_SECRET_KEY` is set to an `sk_test_` key. They confirm that `charge_authorization` charges a saved reusable card.
- `client.refunds`, generated from Paystack's OpenAPI spec: `create(transaction:, amount: nil, currency: nil, customer_note: nil, merchant_note: nil)`, `list`, `fetch(id:)` and `retry_with_customer_details(id:, refund_account_details:)`. `transaction` takes the transaction reference or its numeric ID; leave `amount` out for a full refund. `list` filters by `transaction_id:` (sent as `transaction`, documented by Paystack, absent from the spec). Both confirmed against the test API.
- `transfer_recipients.bulk_create(batch:)` for `POST /transferrecipient/bulk`.
- The rest of the Charge API: `charges.create`, `submit_pin`, `submit_phone`, `submit_birthday`, `submit_address` and `check_pending`. `create` takes the channel objects (`bank`, `mobile_money`, `ussd`, `eft`, `qr`, `bank_transfer`, `capitec_pay`) as keyword hashes, plus `currency`, `split_code` and `subaccount`, which Paystack documents and the test API honours although the OpenAPI spec omits them.
- `charges.mobile_money` accepts the `mpesa_offline` and `mptill` providers Paystack documents, and an M-PESA Till `account` in place of `phone`.
- `bin/paystack-scaffold` generates body parameters recorded as docs-only (`spec: null`) in `spec/support/paystack_contract_exceptions.yml`, as it already did for query parameters.
- `customers` covers the rest of Paystack's Customer API: `initialize_authorization`, `verify_authorization`, `initialize_direct_debit`, `direct_debit_activation_charge` and `fetch_mandate_authorizations`, plus cursor pagination on `list` (`use_cursor`, `next_cursor`, `previous`).
- `bin/scaffold_names.yml` entries can be a hash, `{name: ..., keywords: {path_variable: ruby_keyword}}`, so a path variable takes the Ruby keyword Paystack's docs use where the spec names it differently.
- `bin/paystack-scaffold` applies body-field entries from `spec/support/paystack_contract_exceptions.yml` (wire name, type and description), as it already did for query parameters.
- `transfers.bulk_create`, `export`, `resend_otp`, `disable_otp`, `finalize_disable_otp` and `enable_otp` (Paystack's Initiate Bulk Transfer, Export Transfers and Transfers Control OTP operations).
- `transactions.export` accepts `currency`, `amount`, `settled` and `payment_page` (documented by Paystack, absent from the OpenAPI spec; confirmed to filter results against the test API) and `subaccount_code`. Paystack's docs also list `perPage` and `page` on Export, but the API ignores them, so the SDK does not offer them.
- `PaystackSdk::Webhook` verifies Paystack webhook signatures (HMAC SHA512, constant-time) and parses events: `valid_signature?`, `verify!`, `construct_event`, `sign`, `trusted_ip?`, plus the documented `EVENTS` and `IP_ADDRESSES`. New errors: `WebhookError`, `InvalidSignatureError`, `InvalidPayloadError`.
- `Response#meta` exposes the pagination metadata (`total`, `page`, `pageCount`, `perPage`) that list endpoints return.
- Default request timeouts (`timeout`, `open_timeout`) and automatic retries with backoff (`max_retries`, `retry_interval`, `retry_non_idempotent`) on SDK-built connections. Writes are only retried on `429`; `GET`s are also retried on network failures and 502/503/504.
- `PaystackSdk::TimeoutError` and `PaystackSdk::ConnectionError` wrap transport failures.
- Connection options are validated and raise `ArgumentError` when invalid or when combined with a pre-built connection.

### Changed

- Faraday constraint relaxed to `>= 2.13, < 3`; added `faraday-retry` dependency.

## [0.1.0] - 2025-06-26

### Changed

#### Error Handling Strategy

- **BREAKING**: Clarified error handling approach - the SDK now consistently follows a two-tier error handling strategy:
  - **Validation errors** (missing/invalid input data) are thrown as exceptions immediately before API calls
  - **API response errors** (business logic, not found, etc.) are returned as unsuccessful Response objects
- Updated documentation to clearly explain when exceptions are thrown vs. when to check `response.success?`

#### Test Infrastructure

- **BREAKING**: Standardized all test specifications to use connection doubles instead of Faraday-specific mocks
- Updated test pattern across all resource specs to use `instance_double("PaystackSdk::Connection")` for better framework independence
- All tests now follow consistent mocking pattern with `PaystackSdk::Response.new()` expectations

#### Documentation

- Enhanced README with comprehensive error handling examples
- Added validation error examples showing `MissingParamError`, `InvalidFormatError`, and `InvalidValueError`
- Updated Quick Start guide to demonstrate proper exception handling
- Clarified the difference between input validation (exceptions) and API response handling (Response objects)

### Improved

- Better separation of concerns between input validation and API error handling
- More consistent test suite that's not tied to specific HTTP client implementation
- Clearer developer experience with predictable error handling patterns

## [0.0.9] - 2025-06-26

### Added

- Verification resource with support for:
  - Resolving bank accounts
  - Resolving card BINs
  - Validating accounts (with required and optional fields)
- Registered `verification` resource in the main client for easy access
- Regression tests for all Verification resource methods, including required field validation and full parameter support

### Changed

- Fix the link for listing banks API

## [0.0.8] - 2025-06-26

### Added

- Banks resource with support for listing banks and currency validation
- Regression tests for Banks resource, including validation for allowed currencies
- Registered `banks` resource in the main client for easy access

### Improved

- Validation for allowed currency values in Banks resource for safer API usage

## [0.0.7] - 2025-06-25

### Added

- Transfer Recipients resource with full CRUD operations (create, list, fetch, update, delete)
- Transfers resource with full API support (create/initiate, list, fetch, finalize, verify)
- All resource methods now use `handle_response` for consistent response handling
- Regression tests for Transfer Recipients and Transfers resources, ensuring response wrapping and validation

### Changed

- Registered `transfer_recipients` and `transfers` resources in the main client for easy access
- Updated specs to verify that all resource methods wrap responses using `PaystackSdk::Response`

### Improved

- Enhanced test coverage for new resources and response handling
- Improved code consistency by enforcing response wrapping and validation patterns across all new resources

## [0.0.6] - 2025-06-10

### Added

- Customers resource with full CRUD operations (create, list, fetch, update)
- Customer validation and risk action management features
- Customer authorization deactivation functionality
- Comprehensive documentation for Customers API in README

### Changed

- Improved test consistency by standardizing response body format using string keys with hashrocket notation (`=>`) across all test specifications
- Enhanced error handling specificity in tests by using appropriate error classes (`InvalidValueError`, `InvalidFormatError`, `MissingParamError`) instead of generic `Error` class

### Improved

- Better test coverage and reliability with consistent response format handling
- More precise error validation ensuring proper exception types are raised for different validation failures
- Enhanced documentation with comprehensive examples for all customer operations

## [0.0.5] - 2025-05-15

### Added

- Connection utilities module for improved API connection handling and management
- Enhanced connection configuration and error handling capabilities

## [0.0.4] - 2025-05-15

### Added

- Enhanced transaction resource validations with comprehensive parameter checking
- New transaction methods: `charge_authorization` and `partial_debit`
- Flexible `list` method accepting additional parameters for advanced API requests

### Changed

- Updated SDK authentication to use `secret_key` instead of `api_key` for consistency with Paystack documentation
- Improved transaction method names for better clarity and consistency
- Enhanced README documentation with comprehensive usage examples

### Improved

- Better validation error messages and handling
- More robust parameter validation across all transaction methods

## [0.0.3] - 2025-05-13

### Changed

- Renamed `#initialize_transaction` method to `#initiate` for better clarity and consistency with Paystack API
- Updated .gitignore to exclude Gemfile.lock from version control

### Fixed

- Corrected typos in README documentation regarding original API response handling

## [0.0.2] - 2025-05-11

### Added

- Comprehensive Response class for Paystack API response handling with dynamic attribute access
- Enhanced response object capabilities with better data access patterns
- Improved debugging support for development

### Changed

- Refactored transaction specs to utilize PaystackSdk::Response for better consistency
- Removed redundant success? method in favor of centralized Response handling
- Enhanced documentation clarity on original API response handling

### Improved

- Better response handling architecture across all SDK components
- More intuitive API for accessing response data and metadata

## [0.0.1] - 2025-05-10

### Added

- Initial release of Paystack Ruby SDK
- Basic transaction operations (initiate, verify)
- Foundational SDK architecture with modular design
- Comprehensive error handling framework
- Basic client initialization and configuration
- Initial documentation and usage examples
