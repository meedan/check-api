class DeleteSmoochBotComments < ActiveRecord::Migration[4.2]
  def change
    Rails.cache.write('check:migrate:delete_smooch_bot_comments', Time.now)
  end
end
