require_relative "../validations"

module PaystackSdk
  module Resources
    class TransferRecipients < Base
      # Create a transfer recipient
      # @see https://paystack.com/docs/api/transfer-recipient/#create
      def create(params)
        validate_hash!(input: params, name: "TransferRecipient params")
        validate_required_params!(
          payload: params,
          required_params: %i[type name account_number bank_code],
          operation_name: "Create Transfer Recipient"
        )
        handle_response(@connection.post("/transferrecipient", params))
      end

      # List transfer recipients
      # @see https://paystack.com/docs/api/transfer-recipient/#list
      def list(query = {})
        handle_response(@connection.get("/transferrecipient", query))
      end

      # Fetch a transfer recipient
      # @see https://paystack.com/docs/api/transfer-recipient/#fetch
      def fetch(recipient_code:)
        validate_presence!(value: recipient_code, name: "recipient_code")
        handle_response(@connection.get("/transferrecipient/#{recipient_code}"))
      end

      # Update a transfer recipient
      # @see https://paystack.com/docs/api/transfer-recipient/#update
      def update(recipient_code:, params:)
        validate_presence!(value: recipient_code, name: "recipient_code")
        validate_hash!(input: params, name: "Update TransferRecipient params")
        handle_response(@connection.put("/transferrecipient/#{recipient_code}", params))
      end

      # Delete a transfer recipient
      # @see https://paystack.com/docs/api/transfer-recipient/#delete
      def delete(recipient_code:)
        validate_presence!(value: recipient_code, name: "recipient_code")
        handle_response(@connection.delete("/transferrecipient/#{recipient_code}"))
      end
    end
  end
end
