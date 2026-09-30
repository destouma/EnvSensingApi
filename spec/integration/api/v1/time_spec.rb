require 'swagger_helper'

RSpec.describe 'Time', type: :request do
  path '/api/v1/time' do
    get 'Current server time' do
      tags 'Time'
      description 'Public (no token). Lets a device set its clock before posting readings.'
      produces 'application/json'
      security []

      response '200', 'current time' do
        schema type: :object,
               properties: {
                 current_date_time: { type: :string, format: 'date-time' },
                 epoch: { type: :integer, description: 'Unix time in seconds' }
               },
               required: %w[current_date_time epoch],
               additionalProperties: false
        run_test!
      end
    end
  end
end
