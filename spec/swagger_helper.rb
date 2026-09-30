require 'rails_helper'

# swagger/v1/swagger.yaml is generated from the specs in spec/integration:
#   RAILS_ENV=test bin/rails rswag:specs:swaggerize
# Each documented response is an executed example, validated against the schemas below.
RSpec.configure do |config|
  config.openapi_root = Rails.root.join('swagger').to_s

  date_time = { type: :string, format: 'date-time', example: '2026-09-30T12:00:00.000Z' }
  public_uuid = { type: :string, pattern: '^[A-Za-z0-9][A-Za-z0-9_:-]{0,63}$', example: '123-123-000-001' }
  device_properties = {
    uuid: public_uuid,
    name: { type: :string, example: 'MKR1010 BME280' },
    description: { type: :string, nullable: true },
    created_at: date_time,
    sensors: { type: :array, items: { '$ref' => '#/components/schemas/sensor' } }
  }

  config.openapi_specs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'Environmental Sensing API',
        version: 'v1',
        description: <<~DESC,
          API to store and read environmental sensor readings and camera pictures.

          **Authentication.** Every endpoint except `GET /api/v1/time` requires an `Authorization: Bearer <token>` header:
          a device token (`esd_...`) for devices, or an API key (`esk_...`) with scope `read` or `admin`.
          Responses: 401 without a valid token, 403 when the token is not allowed for the endpoint,
          429 when rate limited (see the `Retry-After` header).

          **Errors** always have the shape `{"error": {"code", "message", "details"}}`.

          **Pagination.** Readings and pictures are returned newest first. Pass the `next_cursor` of a page
          as `cursor` to get the next one; it is `null` on the last page.
        DESC
        contact: { name: 'API support', email: 'mdsoftengr@gmail.com' }
      },
      servers: [
        { url: 'http://{defaultHost}', variables: { defaultHost: { default: 'localhost:3000' } } }
      ],
      security: [{ apiKey: [] }],
      tags: [
        { name: 'Devices' }, { name: 'Sensors' }, { name: 'Sensor types' },
        { name: 'Readings' }, { name: 'Pictures' }, { name: 'Time' }
      ],
      paths: {},
      components: {
        securitySchemes: {
          deviceToken: {
            type: :http, scheme: :bearer,
            description: 'Device token (esd_...). Lets a device post readings and pictures for its own sensors only.'
          },
          apiKey: {
            type: :http, scheme: :bearer,
            description: 'API key (esk_...). Scope read: GET endpoints. Scope admin: also creates devices and sensors.'
          }
        },
        schemas: {
          error: {
            type: :object,
            properties: {
              error: {
                type: :object,
                properties: {
                  code: { type: :string, example: 'validation_failed' },
                  message: { type: :string, example: 'Validation failed' },
                  details: {
                    type: :object,
                    description: 'Field name => list of messages (validation errors only)',
                    additionalProperties: { type: :array, items: { type: :string } }
                  }
                },
                required: %w[code message],
                additionalProperties: false
              }
            },
            required: %w[error],
            additionalProperties: false
          },
          sensor_type: {
            type: :object,
            properties: {
              id: { type: :integer, example: 1 },
              name: { type: :string, example: 'Temperature' },
              unit: { type: :string, example: 'C' },
              pow10multi: { type: :integer, description: 'Real value = value * 10^pow10multi', example: -2 }
            },
            required: %w[id name unit pow10multi],
            additionalProperties: false
          },
          sensor: {
            type: :object,
            properties: {
              uuid: public_uuid,
              name: { type: :string, example: 'Temperature Sensor' },
              description: { type: :string, nullable: true },
              device_uuid: public_uuid,
              sensor_type: { '$ref' => '#/components/schemas/sensor_type' }
            },
            required: %w[uuid name description device_uuid sensor_type],
            additionalProperties: false
          },
          device: {
            type: :object,
            properties: device_properties,
            required: %w[uuid name description created_at sensors],
            additionalProperties: false
          },
          device_with_token: {
            type: :object,
            description: 'A device just created, with its device token (shown only once)',
            properties: device_properties.merge(api_token: { type: :string, example: 'esd_...' }),
            required: %w[uuid name description created_at sensors api_token],
            additionalProperties: false
          },
          reading: {
            type: :object,
            properties: {
              id: { type: :integer },
              value: { type: :integer, description: 'Raw integer value, see sensor_type.pow10multi', example: 2150 },
              date_time: date_time,
              sensor_uuid: public_uuid
            },
            required: %w[id value date_time],
            additionalProperties: false
          },
          picture: {
            type: :object,
            properties: {
              id: { type: :integer },
              date_time: date_time,
              sensor_uuid: public_uuid,
              size: { type: :integer, description: 'File size in bytes' },
              url: { type: :string, example: '/api/v1/pictures/1/file' }
            },
            required: %w[id date_time sensor_uuid size url],
            additionalProperties: false
          },
          next_cursor: {
            type: :string, nullable: true,
            description: 'Pass as cursor to get the next page; null on the last page'
          }
        }
      }
    }
  }

  config.openapi_format = :yaml
end
