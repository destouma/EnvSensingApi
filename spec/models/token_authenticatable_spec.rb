require 'rails_helper'

RSpec.describe TokenAuthenticatable do
  let(:device) { Device.create!(uuid: 'dev-1', name: 'MKR1010') }

  it 'stores only the digest of a generated token' do
    device_token = device.device_tokens.create!

    expect(device_token.token).to match(/\Aesd_[A-Za-z0-9_-]{43}\z/)
    expect(device_token.token_digest).to eq(Digest::SHA256.hexdigest(device_token.token))
    expect(DeviceToken.find(device_token.id).token).to be_nil
  end

  it 'finds active tokens only, and only with the right prefix' do
    device_token = device.device_tokens.create!
    api_key = ApiKey.create!(name: 'reader', scope: 'read')

    expect(DeviceToken.find_by_token(device_token.token)).to eq(device_token)
    expect(ApiKey.find_by_token(api_key.token)).to eq(api_key)
    expect(ApiKey.find_by_token(device_token.token)).to be_nil
    expect(DeviceToken.find_by_token(nil)).to be_nil

    device_token.revoke!
    expect(DeviceToken.find_by_token(device_token.token)).to be_nil
  end

  it 'restricts API key scopes' do
    expect(ApiKey.new(name: 'x', scope: 'root')).not_to be_valid
    expect(ApiKey.new(name: 'x', scope: 'admin').allows?(:read)).to be(true)
    expect(ApiKey.new(name: 'x', scope: 'read').allows?(:admin)).to be(false)
  end
end
