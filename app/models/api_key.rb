class ApiKey < ApplicationRecord
  include TokenAuthenticatable
  token_prefix "esk_"

  SCOPES = %w(read admin).freeze

  validates :name, presence: true
  validates :scope, inclusion: { in: SCOPES }

  def admin?
    scope == "admin"
  end

  # admin implies read
  def allows?(required_scope)
    admin? || scope == required_scope.to_s
  end
end
