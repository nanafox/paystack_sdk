# frozen_string_literal: true

RSpec.describe PaystackSdk::Resources::Transfers do
  let(:connection) { instance_double('PaystackSdk::Connection') }
  let(:transfers) { described_class.new(connection) }
  let(:params) do
    {
      source: 'balance',
      amount: 50_000,
      recipient: 'RCP_1234567890',
      reason: 'Test transfer'
    }
  end

  describe '#create' do
    it 'creates a transfer and wraps response' do
      response_double = double('Response', success?: true)
      expect(connection).to receive(:post)
        .with('/transfer', params)
        .and_return(response_double)
      expect(PaystackSdk::Response).to receive(:new).with(response_double)
      transfers.create(params)
    end

    it 'raises error for missing required params' do
      expect do
        transfers.create({})
      end.to raise_error(PaystackSdk::MissingParamError)
    end
  end

  describe '#list' do
    it 'lists transfers and wraps response' do
      response_double = double('Response', success?: true)
      expect(connection).to receive(:get)
        .with('/transfer', {})
        .and_return(response_double)
      expect(PaystackSdk::Response).to receive(:new).with(response_double)
      transfers.list
    end
  end

  describe '#fetch' do
    it 'fetches a transfer and wraps response' do
      response_double = double('Response', success?: true)
      expect(connection).to receive(:get)
        .with('/transfer/12345')
        .and_return(response_double)
      expect(PaystackSdk::Response).to receive(:new).with(response_double)
      transfers.fetch(id: '12345')
    end
  end

  describe '#finalize' do
    it 'finalizes a transfer and wraps response' do
      response_double = double('Response', success?: true)
      expect(connection).to receive(:post)
        .with('/transfer/finalize_transfer', { transfer_code: 'TRF_abc', otp: '123456' })
        .and_return(response_double)
      expect(PaystackSdk::Response).to receive(:new).with(response_double)
      transfers.finalize(transfer_code: 'TRF_abc', otp: '123456')
    end
  end

  describe '#verify' do
    it 'verifies a transfer and wraps response' do
      response_double = double('Response', success?: true)
      expect(connection).to receive(:get)
        .with('/transfer/verify/abc123')
        .and_return(response_double)
      expect(PaystackSdk::Response).to receive(:new).with(response_double)
      transfers.verify(reference: 'abc123')
    end
  end
end
