# == Schema Information
#
# Table name: api_keys
#
#  id           :bigint           not null, primary key
#  last_used_at :datetime
#  name         :string           not null
#  revoked_at   :datetime
#  scope        :string           not null
#  token_digest :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_api_keys_on_token_digest  (token_digest) UNIQUE
#
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
