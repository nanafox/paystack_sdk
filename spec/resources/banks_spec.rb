# frozen_string_literal: true

RSpec.describe PaystackSdk::Resources::Banks do
  let(:connection) { instance_double('PaystackSdk::Connection') }
  let(:banks) { described_class.new(connection) }

  describe '#list' do
    it 'lists banks and wraps response' do
      response_double = double('Response', success?: true)
      expect(connection).to receive(:get)
        .with('/bank', {})
        .and_return(response_double)
      expect(PaystackSdk::Response).to receive(:new).with(response_double)
      banks.list
    end

    it 'passes query params to the API' do
      response_double = double('Response', success?: true)
      expect(connection).to receive(:get)
        .with('/bank', { currency: 'NGN' })
        .and_return(response_double)
      expect(PaystackSdk::Response).to receive(:new).with(response_double)
      banks.list(currency: 'NGN')
    end

    it 'raises error for invalid currency' do
      expect do
        banks.list(currency: 'INVALID')
      end.to raise_error(PaystackSdk::InvalidValueError, /currency/)
    end
  end
end
