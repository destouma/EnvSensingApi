require 'rails_helper'

RSpec.describe 'Rails Admin access', type: :request do
  def basic_auth(username, password)
    { 'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials(username, password) }
  end

  context 'with credentials configured' do
    around do |example|
      ENV['ADMIN_USERNAME'] = 'admin'
      ENV['ADMIN_PASSWORD'] = 's3cret'
      example.run
    ensure
      ENV.delete('ADMIN_USERNAME')
      ENV.delete('ADMIN_PASSWORD')
    end

    it 'requires authentication' do
      get '/admin/device'
      expect(response).to have_http_status(:unauthorized)
    end

    it 'rejects wrong credentials' do
      get '/admin/device', headers: basic_auth('admin', 'wrong')
      expect(response).to have_http_status(:unauthorized)
    end

    it 'allows valid credentials' do
      get '/admin/device', headers: basic_auth('admin', 's3cret')
      expect(response).to have_http_status(:ok)
    end
  end

  context 'without credentials configured in production' do
    before { allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production')) }

    it 'denies access' do
      get '/admin/device'
      expect(response).to have_http_status(:forbidden)
    end
  end
end
