class SetListedBots < ActiveRecord::Migration[5.2]
  def change
    # These bots should be marked as "listed", so they appear on the UI
    BotUser.where(login: ['fetch', 'keep', 'slack']).each do |bot|
      bot.set_listed = true
      bot.save!
    end
  end
end
