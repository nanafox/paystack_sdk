# Terminals

A Paystack Terminal is a physical point-of-sale device linked to your integration. **None of this was verified against the Paystack API:** the test account used to build the SDK (Ghana) gets `403` "Sorry, this feature is not yet available in your country." from every Terminal GET (list, fetch, status, event status; the others were not called), which the SDK returns as an unsuccessful `Response`. The methods follow Paystack's OpenAPI spec and docs page.

## List and Fetch Terminals

```ruby
# Cursor pagination: pass the meta's next or previous cursor back. per_page is sent as the spec names
# it (the docs say perPage; which one the API reads is unverified).
response = paystack.terminals.list(per_page: 20)
paystack.terminals.list(next_cursor: response.meta.next) if response.success? && response.meta.next

terminal = paystack.terminals.fetch(terminal_id: "2872S934")

# Check a terminal is online and available before sending it an event
status = paystack.terminals.fetch_status(terminal_id: "2872S934")
puts "online: #{status.data.online}, available: #{status.data.available}"
```

## Send an Event and Check It

```ruby
# Pushes an event to the physical device. type is invoice or transaction; action is process or view
# (invoice) or process or print (transaction).
event = paystack.terminals.send_event(
  terminal_id: "2872S934",
  type: "invoice",
  action: "process",
  data: {id: 7895939, reference: 4634337895939}
)

paystack.terminals.fetch_event_status(terminal_id: "2872S934", event_id: event.data.id) # data.delivered
```

The spec marks `type`, `action` and `data` optional and the SDK follows it; the docs list them without an "optional" badge.

## Update, Commission and Decommission

```ruby
paystack.terminals.update(terminal_id: "2872S934", name: "Front desk", address: "Accra")

# Link or unlink a debug device by its serial number
paystack.terminals.commission(serial_number: "1111150412230003899")
paystack.terminals.decommission(serial_number: "1111150412230003899")
```
