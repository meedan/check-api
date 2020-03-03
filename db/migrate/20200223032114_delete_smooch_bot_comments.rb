class DeleteSmoochBotComments < ActiveRecord::Migration
  def change
    Rails.cache.write('check:migrate:delete_smooch_bot_comments', Time.now)
  end
end
