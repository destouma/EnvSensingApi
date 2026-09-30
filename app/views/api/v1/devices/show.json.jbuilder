json.partial! "api/v1/devices/device", device: @device
# Only present in the response that created the device: the token is not stored in plaintext.
json.api_token @device_token.token if @device_token
