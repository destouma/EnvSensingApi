# Token management. Plaintext tokens are printed once and never stored.
#
#   rake "auth:create_api_key[grafana,read]"
#   rake auth:list_api_keys
#   rake "auth:revoke_api_key[3]"
#   rake "auth:issue_device_token[123-123-000-000,firmware v2]"
#   rake "auth:list_device_tokens[123-123-000-000]"
#   rake "auth:revoke_device_token[7]"
namespace :auth do
  def print_token_rows(tokens)
    tokens.each do |t|
      status = t.revoked? ? "revoked #{t.revoked_at}" : "active"
      label = t.respond_to?(:scope) ? "#{t.name} (#{t.scope})" : t.name
      puts format("%-5s %-30s %-35s last used: %s", t.id, label, status, t.last_used_at || "never")
    end
  end

  desc "Create an API key: auth:create_api_key[name,scope] (scope: read|admin)"
  task :create_api_key, [:name, :scope] => :environment do |_t, args|
    api_key = ApiKey.create!(name: args[:name], scope: args[:scope])
    puts "API key ##{api_key.id} (#{api_key.scope}) created. Store it now, it will not be shown again:"
    puts api_key.token
  end

  desc "List API keys"
  task list_api_keys: :environment do
    print_token_rows(ApiKey.order(:id))
  end

  desc "Revoke an API key: auth:revoke_api_key[id]"
  task :revoke_api_key, [:id] => :environment do |_t, args|
    ApiKey.find(args[:id]).revoke!
    puts "API key ##{args[:id]} revoked"
  end

  desc "Issue a new token for a device: auth:issue_device_token[device_uuid,name]"
  task :issue_device_token, [:device_uuid, :name] => :environment do |_t, args|
    device = Device.find_by!(uuid: args[:device_uuid])
    device_token = device.device_tokens.create!(name: args[:name])
    puts "Token ##{device_token.id} issued for device #{device.uuid}. Store it now, it will not be shown again:"
    puts device_token.token
  end

  desc "List a device's tokens: auth:list_device_tokens[device_uuid]"
  task :list_device_tokens, [:device_uuid] => :environment do |_t, args|
    print_token_rows(Device.find_by!(uuid: args[:device_uuid]).device_tokens.order(:id))
  end

  desc "Revoke a device token: auth:revoke_device_token[id]"
  task :revoke_device_token, [:id] => :environment do |_t, args|
    DeviceToken.find(args[:id]).revoke!
    puts "Device token ##{args[:id]} revoked"
  end
end
