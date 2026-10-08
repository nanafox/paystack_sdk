# Changelog

## [Unreleased]

### Fixed

- `Response#[]` and `Response#key?` returned `nil`/`false` for every key on real Paystack bodies (string keys). Both now accept strings or symbols.
- `Customers#deactivate_authorization` called a non-existent endpoint (`customer/deactivate_authorization`). It now posts to Paystack's documented `POST /customer/authorization/deactivate`.
- `429` responses now raise `RateLimitError` (previously swallowed as a client error because the `400..499` branch matched first). `retry_after` is read from Paystack's `x-ratelimit-reset` header (nil when absent) instead of the undocumented `Retry-After`.

### Added

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
