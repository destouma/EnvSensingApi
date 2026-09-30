# spec/integration/sensors_spec.rb
require 'swagger_helper'

describe 'Sensor types API' do
  let(:Authorization) { "Bearer #{ApiKey.create!(name: 'docs', scope: 'read').token}" }

  path '/api/v1/sensor_types' do
    get 'Retrives all sensor types' do
      tags 'Sensor types'
      produces 'application/json', 'application/xml'
      # parameter name: :id, :in => :path, :type => :string

      response '200', 'sensor types  found' do
        run_test!
      end
    end
  end

end