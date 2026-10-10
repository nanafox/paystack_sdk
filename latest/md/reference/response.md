# Response

The Response class provides a wrapper around Paystack API responses.
It offers convenient access to response data through dot notation and
supports both direct attribute access and hash/array-like operations.

The Response class handles API responses that use string keys (as returned
by the Paystack API) and provides seamless access through both string and
symbol notation.

Features:
- Dynamic attribute access via dot notation (response.data.attribute)
- Hash-like access (response[:key] or response["key"])
- Array-like access for list responses (response[0])
- Iteration support (response.each)
- Automatic handling of nested data structures
- Consistent handling of string-keyed API responses

```ruby
  response = PaystackSdk::Response.new(api_response)

  # Check if request was successful
  if response.success?
    # Access data using dot notation
    puts response.data.authorization_url
    puts response.data.reference

    # Or directly from response
    puts response.authorization_url
  else
    puts "Error: #{response.error_message}"
  end

## Methods

### `error_message`

```ruby
response.error_message
```

**Returns** `String, nil` Error message if the request failed

### `api_message`

```ruby
response.api_message
```

**Returns** `String, nil` API message from the response

### `message`

```ruby
response.message
```

**Returns** `String, nil` API message from the response, if available

### `raw_data`

```ruby
response.raw_data
```

**Returns** `Hash, Array, Object` The underlying data

### `status_code`

```ruby
response.status_code
```

**Returns** `Integer` The status code of the API response

### `meta`

```ruby
response.meta
```

Pagination metadata that Paystack returns with list responses
(e.g. `total`, `page`, `pageCount`, `perPage`).

**Returns** `Response, nil` The wrapped `meta` object, or nil if the response has none

**Example**

```ruby
response = transactions.list
response.meta.total       # => 40
response.meta.pageCount   # => 2
```

### `data`

```ruby
response.data
```

Returns a Response object for the data
This enables chained access like response.data.key

**Returns** `Response` self, to enable chaining

### `success?`

```ruby
response.success?
```

Check if the response was successful

**Returns** `Boolean` true if the API request was successful

### `paid?`

```ruby
response.paid?(amount: nil, currency: nil)
```

Whether this response is a successful payment: the call succeeded and the transaction's
`status` is "success". Paystack's docs say to confirm the amount and currency as well, so
pass the ones you expect and they are compared too.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `amount` | Integer, nil |  | The amount (in the currency's subunit) you expect |
| `currency` | String, nil |  | The currency you expect, e.g. "GHS" |

**Returns** `Boolean`

**Example**

```ruby
response = client.transactions.verify(reference: ref)
response.paid?(amount: 5000, currency: "GHS")
```

### `status?`

```ruby
response.status?(value)
```

Whether the `status` field in the response data equals the given value, e.g.
`response.status?(:send_pin)` on a charge. Paystack names the values; none are assumed here.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `value` | String, Symbol |  |  |

**Returns** `Boolean`

### `failed?`

```ruby
response.failed?
```

Check if the response failed

**Returns** `Boolean` true if the API request failed

### `error_details`

```ruby
response.error_details
```

Get error information if the request failed

**Returns** `Hash` Hash containing error details, or empty hash if successful

### `original_response`

```ruby
response.original_response
```

Returns the original response body
This is useful for debugging or accessing raw data

**Returns** `Hash, Array` The original response body

### `[]`

```ruby
response.[](key)
```

Access data via hash/array notation.
Hash keys can be given as strings or symbols, whichever way the data is keyed.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `key` | Object |  | The key or index to access |

**Returns** `Object, Response` The value for the given key or index

### `dig`

```ruby
response.dig(*keys)
```

Reads a nested value from the data, or nil as soon as a key is missing. Use it for fields Paystack
only sometimes sends (`paid_at`, `authorization.exp_month`...): dot access raises `NoMethodError`
for a key that is not there, which is what you want for a typo and not for an optional field.
Keys can be strings or symbols; an Integer indexes an Array. The value is returned as it is (a
plain Hash, Array or scalar), like `Hash#dig`.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `keys` | Array&lt;String, Symbol, Integer> |  | The path to the value |

**Returns** `Object, nil` The value, or nil if any key along the path is missing

**Raises** `ArgumentError`

**Example**

```ruby
response.dig(:authorization, :authorization_code) # => "AUTH_..." or nil
```

### `key?`

```ruby
response.key?(key)
```

Check if key exists in hash (as a string or a symbol)

| Parameter | Type | Required | Description |
|---|---|---|---|
| `key` | Symbol, String |  | The key to check |

**Returns** `Boolean` Whether the key exists

### `each`

```ruby
response.each
```

Iterate through hash entries or array items

**Returns** `Response, Enumerator` Self for chaining or Enumerator if no block given

### `size`

```ruby
response.size
```

**Returns** `Integer` The number of items

### `length`

```ruby
response.length
```

**Returns** `Integer` The number of items

### `count`

```ruby
response.count
```

**Returns** `Integer` The number of items

### `empty?`

```ruby
response.empty?
```

**Returns** `Boolean` Whether the collection is empty

### `first`

```ruby
response.first
```

**Returns** `Object, Response` The first item, wrapped if necessary

### `last`

```ruby
response.last
```

**Returns** `Object, Response` The last item, wrapped if necessary


