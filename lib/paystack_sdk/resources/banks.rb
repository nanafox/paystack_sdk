require_relative '../validations'

module PaystackSdk
  module Resources
    class Banks < Base
      # List banks
      # @see https://paystack.com/docs/api/miscellaneous/#bank
      def list(query = {})
        if query.key?(:currency)
          validate_allowed_values!(
            value: query[:currency],
            name: 'currency',
            allowed_values: %w[NGN GHS ZAR KES USD]
          )
        end

        handle_response(@connection.get('/bank', query))
      end
    end
  end
end
