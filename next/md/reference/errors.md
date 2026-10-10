# Errors

Every error the SDK raises inherits from `PaystackSdk::Error`.

| Class | Inherits from | When |
|---|---|---|
| `PaystackSdk::APIError` | `PaystackSdk::Error` | Base class for API errors. Raised when the Paystack API returns an error response. |
| `PaystackSdk::AuthenticationError` | `PaystackSdk::APIError` | Raised when authentication fails |
| `PaystackSdk::ConnectionError` | `PaystackSdk::Error` | Raised when a request could not reach Paystack (DNS, refused, reset, ...) after all retries were exhausted. |
| `PaystackSdk::Error` | `StandardError` | Base error class for all Paystack SDK errors. All SDK-specific exceptions inherit from this class. |
| `PaystackSdk::InvalidFormatError` | `PaystackSdk::ValidationError` | Raised when a parameter has an invalid format. Contains both the parameter name and expected format for detailed error handling. |
| `PaystackSdk::InvalidPayloadError` | `PaystackSdk::WebhookError` | Raised when a correctly signed webhook body is not a JSON event. |
| `PaystackSdk::InvalidSignatureError` | `PaystackSdk::WebhookError` | Raised when a webhook's signature does not match its payload. Treat the request as not coming from Paystack. |
| `PaystackSdk::InvalidValueError` | `PaystackSdk::ValidationError` | Raised when a parameter has an invalid value. Contains both the parameter name and the reason for the invalid value. |
| `PaystackSdk::MissingParamError` | `PaystackSdk::ValidationError` | Raised when a required parameter is missing. Contains the parameter name for detailed error handling. |
| `PaystackSdk::RateLimitError` | `PaystackSdk::APIError` | Raised when rate limiting is encountered |
| `PaystackSdk::ResourceNotFoundError` | `PaystackSdk::APIError` | Raised when a resource is not found |
| `PaystackSdk::ServerError` | `PaystackSdk::APIError` | Raised when the server returns a 5xx error |
| `PaystackSdk::TimeoutError` | `PaystackSdk::ConnectionError` | Raised when a request to Paystack timed out after all retries were exhausted. |
| `PaystackSdk::ValidationError` | `PaystackSdk::Error` | Base class for all validation errors. Raised when input parameters fail validation before API calls. |
| `PaystackSdk::WebhookError` | `PaystackSdk::Error` | Base class for webhook errors. |
