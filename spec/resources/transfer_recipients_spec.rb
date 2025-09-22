RSpec.describe PaystackSdk::Resources::TransferRecipients do
  let(:connection) { instance_double("PaystackSdk::Connection") }
  let(:recipients) { described_class.new(connection) }
  let(:params) do
    {
      type: "nuban",
      name: "Jane Doe",
      account_number: "0001234567",
      bank_code: "058",
      currency: "NGN"
    }
  end

  describe "#create" do
    it "creates a transfer recipient and wraps response" do
      response_double = double("Response", success?: true)
      expect(connection).to receive(:post)
        .with("/transferrecipient", params)
        .and_return(response_double)
      expect(PaystackSdk::Response).to receive(:new).with(response_double)
      recipients.create(params)
    end

    it "raises error for missing required params" do
      expect do
        recipients.create({})
      end.to raise_error(PaystackSdk::MissingParamError)
    end
  end

  describe "#list" do
    it "lists transfer recipients and wraps response" do
      response_double = double("Response", success?: true)
      expect(connection).to receive(:get)
        .with("/transferrecipient", {})
        .and_return(response_double)
      expect(PaystackSdk::Response).to receive(:new).with(response_double)
      recipients.list
    end
  end

  describe "#fetch" do
    it "fetches a transfer recipient and wraps response" do
      response_double = double("Response", success?: true)
      expect(connection).to receive(:get)
        .with("/transferrecipient/RCP_123")
        .and_return(response_double)
      expect(PaystackSdk::Response).to receive(:new).with(response_double)
      recipients.fetch(recipient_code: "RCP_123")
    end
  end

  describe "#update" do
    it "updates a transfer recipient and wraps response" do
      response_double = double("Response", success?: true)
      expect(connection).to receive(:put)
        .with("/transferrecipient/RCP_123", {name: "New Name"})
        .and_return(response_double)
      expect(PaystackSdk::Response).to receive(:new).with(response_double)
      recipients.update(recipient_code: "RCP_123", params: {name: "New Name"})
    end
  end

  describe "#delete" do
    it "deletes a transfer recipient and wraps response" do
      response_double = double("Response", success?: true)
      expect(connection).to receive(:delete)
        .with("/transferrecipient/RCP_123")
        .and_return(response_double)
      expect(PaystackSdk::Response).to receive(:new).with(response_double)
      recipients.delete(recipient_code: "RCP_123")
    end
  end
end
