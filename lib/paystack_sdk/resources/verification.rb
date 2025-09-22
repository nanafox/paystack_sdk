require_relative "../validations"
require_relative "base"

module PaystackSdk
  module Resources
    class Verification < Base
      # Resolve Bank Account
      # @see https://paystack.com/docs/api/verification/#resolve-bank-account
      def resolve_account(account_number:, bank_code:)
        validate_presence!(value: account_number, name: "account_number")
        validate_presence!(value: bank_code, name: "bank_code")
        handle_response(@connection.get("/bank/resolve", {account_number: account_number, bank_code: bank_code}))
      end

      # Resolve Card BIN
      # @see https://paystack.com/docs/api/verification/#resolve-card-bin
      def resolve_card_bin(bin)
        validate_presence!(value: bin, name: "bin")
        handle_response(@connection.get("/decision/bin/#{bin}"))
      end

      # Validate Account
      # @see https://paystack.com/docs/api/verification/#validate-account
      # Required: account_number, account_name, account_type, bank_code, country_code, document_type
      # Optional: document_number
      def validate_account(params)
        validate_required_params!(
          payload: params,
          required_params: %i[account_number account_name account_type bank_code country_code document_type],
          operation_name: "Validate Account"
        )
        handle_response(@connection.post("/bank/validate", params))
      end
    end
  end
end
