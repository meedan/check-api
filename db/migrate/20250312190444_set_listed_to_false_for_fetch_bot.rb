class SetListedToFalseForFetchBot < ActiveRecord::Migration[6.1]
  def change
    # Fetch should not be marked as "listed", so it does not appear on the UI
    BotUser.where(login: 'fetch').each do |bot|
      bot.set_listed = false
      bot.save!
    end
  end
end
