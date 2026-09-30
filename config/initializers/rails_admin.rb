RailsAdmin.config do |config|

  ## == HTTP Basic auth ==
  # Credentials come from ADMIN_USERNAME / ADMIN_PASSWORD. If they are not set, access is
  # denied in production and left open in development/test.
  config.authenticate_with do
    username = ENV["ADMIN_USERNAME"].presence
    password = ENV["ADMIN_PASSWORD"].presence

    if username && password
      authenticate_or_request_with_http_basic("Admin") do |given_username, given_password|
        # Compare both values without short-circuiting to avoid a timing side channel.
        [
          ActiveSupport::SecurityUtils.secure_compare(given_username, username),
          ActiveSupport::SecurityUtils.secure_compare(given_password, password)
        ].all?
      end
    elsif Rails.env.production?
      head :forbidden
    end
  end

  ### Popular gems integration

  ## == Devise ==
  # config.authenticate_with do
  #   warden.authenticate! scope: :user
  # end
  # config.current_user_method(&:current_user)

  ## == CancanCan ==
  # config.authorize_with :cancancan

  ## == Pundit ==
  # config.authorize_with :pundit

  ## == PaperTrail ==
  # config.audit_with :paper_trail, 'User', 'PaperTrail::Version' # PaperTrail >= 3.0.0

  ### More at https://github.com/sferik/rails_admin/wiki/Base-configuration

  ## == Gravatar integration ==
  ## To disable Gravatar integration in Navigation Bar set to false
  # config.show_gravatar = true

  config.actions do
    dashboard                     # mandatory
    index                         # mandatory
    new
    export
    bulk_delete
    show
    edit
    delete
    show_in_app

    ## With an audit adapter, you can add:
    # history_index
    # history_show
  end
end
