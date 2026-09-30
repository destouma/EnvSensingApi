# spec/integration/sensors_spec.rb
require 'swagger_helper'

describe 'Sensors API' do
  let(:Authorization) { "Bearer #{ApiKey.create!(name: 'docs', scope: 'read').token}" }

  path '/api/v1/sensors' do
    get 'Retrives all sensors' do
      tags 'Sensors'
      produces 'application/json', 'application/xml'
      # parameter name: :id, :in => :path, :type => :string

      response '200', 'sensors  found' do
        run_test!
      end
    end
  end

end