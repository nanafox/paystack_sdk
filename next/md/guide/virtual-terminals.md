# Virtual Terminals

A virtual terminal lets you accept in-person payments without a POS device: payments made to it notify its destinations, which are WhatsApp numbers. Check that the product is enabled for your business.

## Create, List, Fetch, Update and Deactivate Virtual Terminals

```ruby
response = paystack.virtual_terminals.create(
  name: "Front desk",
  destinations: [{target: "+2341234567890", name: "Front desk phone"}]
)
puts response.data.code # "VT_..."

# status is active or inactive (the docs list it, the OpenAPI spec omits it)
paystack.virtual_terminals.list(status: "active", per_page: 20)

paystack.virtual_terminals.fetch(code: "VT_MCK5292Z")
paystack.virtual_terminals.update(code: "VT_MCK5292Z", name: "New terminal name")
paystack.virtual_terminals.deactivate(code: "VT_MCK5292Z") # "Terminal set to inactive"
```

On the Paystack test API, `list` and `fetch` work (an account with no terminals gets an empty list). `create` answers 400 `"destinations" is required` without destinations, `"destinations" must contain at least 1 items` with an empty list and `invalid phone number ...` for a target that is not a phone number; `fetch` of an unknown code answers 404 `Virtual Terminal not found`. `create` with a valid body was not run (it needs a real phone number), so the optional `split_code` and `metadata` and the docs' `currency` and `custom_fields` are unverified; the SDK sends what the spec lists.

## Destinations and Split Codes

```ruby
paystack.virtual_terminals.assign_destination(
  code: "VT_MCK5292Z",
  destinations: [{target: "+2341234567890", name: "Another one"}]
)
paystack.virtual_terminals.unassign_destination(code: "VT_MCK5292Z", targets: ["+2341234567890"])

paystack.virtual_terminals.add_split_code(code: "VT_MCK5292Z", split_code: "SPL_98WF13Zu8w5")
# DELETE with a JSON body, as Paystack documents it
paystack.virtual_terminals.remove_split_code(code: "VT_MCK5292Z", split_code: "SPL_98WF13Zu8w5")
```

Assign and unassign destination change who receives payment notifications on WhatsApp, so they were not called against the test API and are described from Paystack's docs only (unverified). The split code operations were only run against an unknown terminal: an unknown split code answers 400 `Invalid split code`, and removing one that is not assigned answers 400 `Virtual Terminal split code assignment does not exist`.
