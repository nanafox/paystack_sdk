# frozen_string_literal: true

RSpec.describe PaystackSdk::Resources::Verification do
  let(:connection) { instance_double('PaystackSdk::Connection') }
  let(:verification) { described_class.new(connection) }

  describe '#resolve_account' do
    it 'resolves a bank account and wraps response' do
      response_double = double('Response', success?: true)
      expect(connection).to receive(:get)
        .with('/bank/resolve', { account_number: '0001234567', bank_code: '058' })
        .and_return(response_double)
      expect(PaystackSdk::Response).to receive(:new).with(response_double)
      verification.resolve_account(account_number: '0001234567', bank_code: '058')
    end

    it 'raises error for missing account_number' do
      expect do
        verification.resolve_account(account_number: nil, bank_code: '058')
      end.to raise_error(PaystackSdk::MissingParamError, /account_number/)
    end

    it 'raises error for missing bank_code' do
      expect do
        verification.resolve_account(account_number: '0001234567', bank_code: nil)
      end.to raise_error(PaystackSdk::MissingParamError, /bank_code/)
    end
  end

  describe '#resolve_card_bin' do
    it 'resolves a card bin and wraps response' do
      response_double = double('Response', success?: true)
      expect(connection).to receive(:get)
        .with('/decision/bin/539983')
        .and_return(response_double)
      expect(PaystackSdk::Response).to receive(:new).with(response_double)
      verification.resolve_card_bin('539983')
    end

    it 'raises error for missing bin' do
      expect do
        verification.resolve_card_bin(nil)
      end.to raise_error(PaystackSdk::MissingParamError, /bin/)
    end
  end

  describe '#validate_account' do
    let(:required_params) do
      {
        account_number: '0001234567',
        account_name: 'Jane Doe',
        account_type: 'personal',
        bank_code: '058',
        country_code: 'NG',
        document_type: 'identityNumber'
      }
    end

    it 'validates an account and wraps response' do
      response_double = double('Response', success?: true)
      expect(connection).to receive(:post)
        .with('/bank/validate', required_params)
        .and_return(response_double)
      expect(PaystackSdk::Response).to receive(:new).with(response_double)
      verification.validate_account(required_params)
    end

    it 'raises error for missing required fields' do
      %i[account_number account_name account_type bank_code country_code document_type].each do |field|
        params = required_params.dup
        params.delete(field)
        expect do
          verification.validate_account(params)
        end.to raise_error(PaystackSdk::MissingParamError, /#{field}/)
      end
    end

    it 'validates an account with all params and wraps response' do
      all_params = required_params.merge(
        document_number: '1234567890123'
      )
      response_double = double('Response', success?: true)
      expect(connection).to receive(:post)
        .with('/bank/validate', all_params)
        .and_return(response_double)
      expect(PaystackSdk::Response).to receive(:new).with(response_double)
      verification.validate_account(all_params)
    end
  end
end
