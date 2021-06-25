class CreateMissingBotVersions < ActiveRecord::Migration[4.2]
  def change
    Rails.cache.write('check:migrate:create_missing_bot_versions:progress', nil)
  end
end
