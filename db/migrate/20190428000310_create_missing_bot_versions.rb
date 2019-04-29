class CreateMissingBotVersions < ActiveRecord::Migration
  def change
    Rails.cache.write('check:migrate:create_missing_bot_versions:progress', nil)
  end
end
