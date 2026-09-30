Rswag::Ui.configure do |c|

  # List the Swagger endpoints that you want to be documented through the swagger-ui
  # The first parameter is the path (absolute or relative to the UI host) to the corresponding
  # endpoint and the second is a title that will be displayed in the document selector
  # NOTE: If you're using rspec-api to expose Swagger files (under swagger_root) as JSON or YAML endpoints,
  # then the list below should correspond to the relative paths for those endpoints

  c.openapi_endpoint '/api-docs/v1/swagger.yaml', 'API V1 Docs'

  # In production the docs (UI and swagger.yaml) are behind the Rails Admin credentials.
  # Without them, a random password nobody knows keeps the docs closed (empty credentials must not work).
  if Rails.env.production?
    c.basic_auth_enabled = true
    c.basic_auth_credentials ENV["ADMIN_USERNAME"].presence || "admin",
                             ENV["ADMIN_PASSWORD"].presence || SecureRandom.hex(32)
  end
end
