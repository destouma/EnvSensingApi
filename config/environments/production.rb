require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings (ignored by Rake tasks).
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Turn on fragment caching in view templates.
  config.action_controller.perform_caching = true

  # Cache assets for far-future expiry since they are all digest stamped.
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # nginx terminates TLS (and redirects plain HTTP), so every request reaching the app came over HTTPS.
  config.assume_ssl = true
  # Secure cookies and HTTPS-only URLs. No HSTS: with the self-signed LAN certificate it would stop
  # browsers from letting you through a certificate warning; install docker/web/ca/ca.crt instead.
  config.force_ssl = true
  config.ssl_options = { hsts: false }

  # nginx sends picture files itself once Rails has checked the token (see docker/web/nginx.conf).
  config.action_dispatch.x_sendfile_header = "X-Accel-Redirect"

  # Log to STDOUT with the current request id as a default log tag.
  config.log_tags = [ :request_id ]
  config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)

  # Change to "debug" to log everything (including potentially personally-identifiable information!).
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Prevent health checks from clogging up the logs.
  config.silence_healthcheck_path = "/up"

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # File store: survives restarts and is shared by Puma workers (rack-attack counters live here).
  config.cache_store = :file_store, Rails.root.join("tmp/cache")

  # Replace the default in-process and non-durable queuing backend for Active Job.
  # config.active_job.queue_adapter = :resque

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [ :id ]

  # Enable DNS rebinding protection and other `Host` header attacks.
  # APP_HOSTS: comma separated host names / IPs clients use (the same as the certificate), e.g.
  # "192.168.1.238,envsensing.lan". Requests for any other Host header are rejected.
  if ENV["APP_HOSTS"].present?
    config.hosts = ENV["APP_HOSTS"].split(",").map(&:strip)
    # The container health check calls http://localhost:3000/up.
    config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
  end
end
