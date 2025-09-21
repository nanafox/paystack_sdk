# frozen_string_literal: true

require_relative 'base'

module PaystackSdk
  module Resources
    # The `Customers` class provides methods for interacting with the Paystack Customers API.
    # It allows you to create, list, fetch, update, and manage customers on your integration.
    #
    # Example usage:
    # ```ruby
    #   customers = PaystackSdk::Resources::Customers.new(secret_key:)
    #
    #   # Create a customer
    #   payload = { email: "customer@email.com", first_name: "Zero", last_name: "Sum" }
    #   response = customers.create(payload)
    #   if response.success?
    #     puts "Customer created successfully."
    #     puts "Customer code: #{response.customer_code}"
    #   else
    #     puts "Error creating customer: #{response.error_message}"
    #   end
    #
    #   # List customers
    #   response = customers.list(per_page: 50, page: 1)
    #
    #   # Fetch a customer
    #   response = customers.fetch("CUS_xxxxx")
    #
    #   # Update a customer
    #   response = customers.update("CUS_xxxxx", { first_name: "John" })
    # ```
    class Customers < PaystackSdk::Resources::Base
      # Creates a new customer.
      #
      # @param payload [Hash] The payload containing customer details.
      # @option payload [String] :email (required) Customer's email address
      # @option payload [String] :first_name Customer's first name
      # @option payload [String] :last_name Customer's last name
      # @option payload [String] :phone Customer's phone number
      # @option payload [Hash] :metadata Additional customer information
      # @return [PaystackSdk::Response] The response from the Paystack API.
      # @raise [PaystackSdk::Error] If the payload is invalid or the API request fails.
      def create(payload)
        validate_fields!(
          payload: payload,
          validations: {
            email: { type: :email, required: true },
            first_name: { type: :string, required: false },
            last_name: { type: :string, required: false },
            phone: { type: :string, required: false }
          }
        )

        response = @connection.post('customer', payload)
        handle_response(response)
      end

      # Lists all customers.
      #
      # @param per_page [Integer] Number of records per page (default: 50)
      # @param page [Integer] Page number to retrieve (default: 1)
      # @param from [String] Start date for filtering
      # @param to [String] End date for filtering
      # @return [PaystackSdk::Response] The response from the Paystack API.
      # @raise [PaystackSdk::Error] If the API request fails.
      def list(per_page: 50, page: 1, **params)
        validate_positive_integer!(value: per_page, name: 'per_page', allow_nil: true)
        validate_positive_integer!(value: page, name: 'page', allow_nil: true)

        validate_date_format!(date_str: params[:from], name: 'from') if params[:from]

        validate_date_format!(date_str: params[:to], name: 'to') if params[:to]

        query_params = { perPage: per_page, page: page }.merge(params)
        response = @connection.get('customer', query_params)
        handle_response(response)
      end

      # Fetches details of a single customer by email or code.
      #
      # @param email_or_code [String] Email or customer code
      # @return [PaystackSdk::Response] The response from the Paystack API.
      # @raise [PaystackSdk::Error] If the parameter is invalid or the API request fails.
      def fetch(email_or_code)
        validate_presence!(value: email_or_code, name: 'email_or_code')
        response = @connection.get("customer/#{email_or_code}")
        handle_response(response)
      end

      # Updates a customer's details.
      #
      # @param code [String] Customer's code
      # @param payload [Hash] The payload containing customer details to update
      # @option payload [String] :first_name Customer's first name
      # @option payload [String] :last_name Customer's last name
      # @option payload [String] :phone Customer's phone number
      # @option payload [Hash] :metadata Additional customer information
      # @return [PaystackSdk::Response] The response from the Paystack API.
      # @raise [PaystackSdk::Error] If the parameters are invalid or the API request fails.
      def update(code, payload)
        validate_presence!(value: code, name: 'code')
        validate_hash!(input: payload, name: 'payload')

        response = @connection.put("customer/#{code}", payload)
        handle_response(response)
      end

      # Validates a customer's identity.
      #
      # @param code [String] Customer's code
      # @param payload [Hash] The payload containing validation details
      # @option payload [String] :country (required) 2 letter country code
      # @option payload [String] :type (required) Type of identification
      # @option payload [String] :account_number Bank account number (required for bank_account type)
      # @option payload [String] :bvn Bank Verification Number
      # @option payload [String] :bank_code Bank code
      # @option payload [String] :first_name Customer's first name
      # @option payload [String] :last_name Customer's last name
      # @return [PaystackSdk::Response] The response from the Paystack API.
      # @raise [PaystackSdk::Error] If the parameters are invalid or the API request fails.
      def validate(code, payload)
        validate_presence!(value: code, name: 'code')
        validate_fields!(
          payload: payload,
          validations: {
            country: { type: :string, required: true },
            type: { type: :string, required: true },
            account_number: { type: :string, required: true },
            bank_code: { type: :string, required: true }
          }
        )

        response = @connection.post("customer/#{code}/identification", payload)
        handle_response(response)
      end

      # Sets the risk action for a customer.
      #
      # @param payload [Hash] The payload containing risk action details
      # @option payload [String] :customer (required) Customer's code or email address
      # @option payload [String] :risk_action (required) Risk action to set ('default', 'allow', or 'deny')
      # @return [PaystackSdk::Response] The response from the Paystack API.
      # @raise [PaystackSdk::MissingParamError] If required parameters are missing
      # @raise [PaystackSdk::InvalidValueError] If risk_action is not one of the allowed values
      # @raise [PaystackSdk::APIError] If the API request fails.
      #
      # @example
      # ```ruby
      #   payload = { customer: "CUS_xxxxx", risk_action: "allow" }
      #   response = customers.set_risk_action(payload)
      #   if response.success?
      #     puts "Risk action updated successfully"
      #   end
      # ```
      def set_risk_action(payload)
        validate_fields!(
          payload: payload,
          validations: {
            customer: { type: :string, required: true },
            risk_action: { type: :inclusion, required: true, allowed_values: %w[default allow deny] }
          }
        )

        response = @connection.post('customer/set_risk_action', payload)
        handle_response(response)
      end

      # Deactivates a customer's authorization.
      #
      # @param payload [Hash] The payload containing authorization details
      # @option payload [String] :authorization_code (required) Authorization code to deactivate
      # @return [PaystackSdk::Response] The response from the Paystack API.
      # @raise [PaystackSdk::Error] If the parameters are invalid or the API request fails.
      def deactivate_authorization(payload)
        validate_fields!(
          payload: payload,
          validations: {
            authorization_code: { type: :string, required: true }
          }
        )

        response = @connection.post('customer/deactivate_authorization', payload)
        handle_response(response)
      end
    end
  end
end
