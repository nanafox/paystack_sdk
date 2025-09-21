require_relative '../validations'

module PaystackSdk
  module Resources
    class Transfers < Base
      # Create a transfer
      # @see https://paystack.com/docs/api/transfer/#initiate
      def create(params)
        validate_hash!(input: params, name: 'Transfer params')
        validate_required_params!(
          payload: params,
          required_params: %i[source amount recipient],
          operation_name: 'Create Transfer'
        )
        handle_response(@connection.post('/transfer', params))
      end

      # List transfers
      # @see https://paystack.com/docs/api/transfer/#list
      def list(query = {})
        handle_response(@connection.get('/transfer', query))
      end

      # Fetch a transfer
      # @see https://paystack.com/docs/api/transfer/#fetch
      def fetch(id:)
        validate_presence!(value: id, name: 'transfer id')
        handle_response(@connection.get("/transfer/#{id}"))
      end

      # Finalize a transfer (OTP)
      # @see https://paystack.com/docs/api/transfer/#finalize
      def finalize(transfer_code:, otp:)
        validate_presence!(value: transfer_code, name: 'transfer_code')
        validate_presence!(value: otp, name: 'otp')
        handle_response(@connection.post('/transfer/finalize_transfer', { transfer_code: transfer_code, otp: otp }))
      end

      # Verify a transfer
      # @see https://paystack.com/docs/api/transfer/#verify
      def verify(reference:)
        validate_presence!(value: reference, name: 'reference')
        handle_response(@connection.get("/transfer/verify/#{reference}"))
      end
    end
  end
end
