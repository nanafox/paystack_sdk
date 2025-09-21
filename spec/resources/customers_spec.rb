# frozen_string_literal: true

RSpec.describe PaystackSdk::Resources::Customers do
  let(:connection) { instance_double('PaystackSdk::Connection') }
  let(:customers) { described_class.new(connection) }

  describe '#create' do
    let(:params) do
      {
        email: 'customer@email.com',
        first_name: 'Zero',
        last_name: 'Sum',
        phone: '+2348123456789'
      }
    end

    context 'with successful response' do
      it 'creates a new customer' do
        response_double = double('Response', success?: true,
                                             data: double('Data', customer_code: 'CUS_xr58yrr2ujlft9k'))
        expect(connection).to receive(:post)
          .with('customer', params)
          .and_return(response_double)
        expect(PaystackSdk::Response).to receive(:new).with(response_double)
                                                      .and_return(response_double)

        response = customers.create(params)
        expect(response).to be_success
        expect(response.data.customer_code).to eq('CUS_xr58yrr2ujlft9k')
      end
    end

    context 'with failed response' do
      it 'returns an unsuccessful response' do
        response_double = double('Response', success?: false, failed?: true,
                                             error_message: 'Customer creation failed')
        expect(connection).to receive(:post)
          .with('customer', params)
          .and_return(response_double)
        expect(PaystackSdk::Response).to receive(:new).with(response_double)
                                                      .and_return(response_double)

        response = customers.create(params)
        expect(response.success?).to be false
        expect(response.failed?).to be true
        expect(response.error_message).to eq('Customer creation failed')
      end
    end

    context 'with validation errors' do
      it 'raises MissingParamError when email is missing' do
        invalid_params = params.except(:email)
        expect { customers.create(invalid_params) }.to raise_error(
          PaystackSdk::MissingParamError,
          'Missing required parameter: email'
        )
      end

      it 'raises InvalidFormatError when email format is invalid' do
        invalid_params = params.merge(email: 'invalid-email')
        expect { customers.create(invalid_params) }.to raise_error(
          PaystackSdk::InvalidFormatError,
          'Invalid format for Email. Expected format: valid email address'
        )
      end
    end
  end

  describe '#list' do
    context 'with successful response' do
      it 'returns a list of customers' do
        response_double = double('Response', success?: true,
                                             data: double('Data', first: double('Customer', customer_code: 'CUS_xr58yrr2ujlft9k')))
        expect(connection).to receive(:get)
          .with('customer', hash_including(perPage: 50, page: 1))
          .and_return(response_double)
        expect(PaystackSdk::Response).to receive(:new).with(response_double)
                                                      .and_return(response_double)

        response = customers.list
        expect(response.success?).to be true
        expect(response.data.first.customer_code).to eq('CUS_xr58yrr2ujlft9k')
      end
    end
  end

  describe '#fetch' do
    let(:email_or_code) { 'CUS_xr58yrr2ujlft9k' }

    context 'with successful response' do
      it 'fetches customer details' do
        response_double = double('Response', success?: true,
                                             data: double('Data', customer_code: email_or_code))
        expect(connection).to receive(:get)
          .with("customer/#{email_or_code}")
          .and_return(response_double)
        expect(PaystackSdk::Response).to receive(:new).with(response_double)
                                                      .and_return(response_double)

        response = customers.fetch(email_or_code)
        expect(response.success?).to be true
        expect(response.data.customer_code).to eq(email_or_code)
      end
    end

    context 'with not found error' do
      it 'returns an unsuccessful response' do
        response_double = double('Response', success?: false, failed?: true,
                                             error_message: 'Customer code/email specified is invalid')
        expect(connection).to receive(:get)
          .with("customer/#{email_or_code}")
          .and_return(response_double)
        expect(PaystackSdk::Response).to receive(:new).with(response_double)
                                                      .and_return(response_double)

        response = customers.fetch(email_or_code)
        expect(response.success?).to be false
        expect(response.failed?).to be true
        expect(response.error_message).to eq('Customer code/email specified is invalid')
      end
    end

    context 'with validation errors' do
      it 'raises MissingParamError when email_or_code is nil' do
        expect { customers.fetch(nil) }.to raise_error(
          PaystackSdk::MissingParamError,
          'Missing required parameter: email_or_code'
        )
      end
    end
  end

  describe '#update' do
    let(:code) { 'CUS_xr58yrr2ujlft9k' }
    let(:params) do
      {
        first_name: 'John',
        last_name: 'Doe',
        phone: '+2348123456789'
      }
    end

    context 'with successful response' do
      before do
        allow(connection).to receive(:put)
          .with("customer/#{code}", params)
          .and_return(Faraday::Response.new(status: 200, body: {
                                              'status' => true,
                                              'message' => 'Customer updated',
                                              'data' => params.merge('customer_code' => code)
                                            }))
      end

      it 'updates customer details' do
        response = customers.update(code, params)
        expect(response.success?).to be true
        expect(response.data.first_name).to eq('John')
      end
    end

    context 'with validation errors' do
      it 'raises InvalidFormatError when payload is not a hash' do
        expect { customers.update(code, 'invalid') }.to raise_error(
          PaystackSdk::InvalidFormatError,
          'Invalid format for payload. Expected format: Hash'
        )
      end

      it 'raises MissingParamError when code is missing' do
        expect { customers.update(nil, params) }.to raise_error(
          PaystackSdk::MissingParamError,
          'Missing required parameter: code'
        )
      end
    end
  end

  describe '#validate' do
    let(:code) { 'CUS_xr58yrr2ujlft9k' }
    let(:params) do
      {
        country: 'NG',
        type: 'bank_account',
        account_number: '0123456789',
        bvn: '20012345677',
        bank_code: '007',
        first_name: 'John',
        last_name: 'Doe'
      }
    end

    context 'with successful response' do
      it 'validates a customer successfully' do
        response_body = {
          'status' => true,
          'message' => 'Customer Identification in progress'
        }

        faraday_response = Faraday::Response.new(status: 202, body: response_body)

        expect(connection).to receive(:post)
          .with("customer/#{code}/identification", params)
          .and_return(faraday_response)

        response = customers.validate(code, params)

        expect(response).to be_success
        expect(response.message).to eq('Customer Identification in progress')
      end
    end

    context 'with validation errors' do
      it 'raises an error when required parameters are missing' do
        invalid_params = params.reject { |k| k == :type }
        expect { customers.validate(code, invalid_params) }
          .to raise_error(PaystackSdk::Error, /type/i)
      end

      it 'raises an error when code is nil' do
        expect { customers.validate(nil, params) }
          .to raise_error(PaystackSdk::MissingParamError, 'Missing required parameter: code')
      end
    end
  end

  describe '#set_risk_action' do
    let(:params) do
      {
        customer: 'CUS_xr58yrr2ujlft9k',
        risk_action: 'allow'
      }
    end

    context 'with successful response' do
      it 'sets risk action successfully' do
        response_body = {
          'status' => true,
          'message' => 'Customer updated',
          'data' => {
            'customer_code' => 'CUS_xr58yrr2ujlft9k',
            'risk_action' => 'allow'
          }
        }

        faraday_response = Faraday::Response.new(status: 200, body: response_body)

        expect(connection).to receive(:post)
          .with('customer/set_risk_action', params)
          .and_return(faraday_response)

        response = customers.set_risk_action(params)

        expect(response).to be_success
        expect(response.risk_action).to eq('allow')
      end
    end

    context 'with validation errors' do
      it 'raises an error when customer is missing' do
        invalid_params = params.reject { |k| k == :customer }
        expect { customers.set_risk_action(invalid_params) }
          .to raise_error(PaystackSdk::Error, /customer/i)
      end

      it 'raises an error when risk_action is invalid' do
        invalid_params = params.merge(risk_action: 'invalid')
        expect { customers.set_risk_action(invalid_params) }
          .to raise_error(PaystackSdk::InvalidValueError, /risk_action/i)
      end
    end
  end

  describe '#deactivate_authorization' do
    let(:params) do
      {
        authorization_code: 'AUTH_72btv547'
      }
    end

    context 'with successful response' do
      it 'deactivates authorization successfully' do
        response_body = {
          'status' => true,
          'message' => 'Authorization has been deactivated'
        }

        faraday_response = Faraday::Response.new(status: 200, body: response_body)

        expect(connection).to receive(:post)
          .with('customer/deactivate_authorization', params)
          .and_return(faraday_response)

        response = customers.deactivate_authorization(params)

        expect(response).to be_success
        expect(response.message).to eq('Authorization has been deactivated')
      end
    end

    context 'with validation errors' do
      it 'raises an error when authorization_code is missing' do
        expect { customers.deactivate_authorization({}) }
          .to raise_error(PaystackSdk::Error, /authorization_code/i)
      end
    end
  end
end
