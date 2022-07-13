class AddRateLimitsToApiKey < ActiveRecord::Migration[5.2]
  def change
    add_column :api_keys, :rate_limits, :jsonb, default: {}
  end
end
