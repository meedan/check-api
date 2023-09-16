class MarkTiplineBotAsDefault < ActiveRecord::Migration[6.1]
  def change
    tb = BotUser.smooch_user
    unless tb.nil?
      tb.default = true
      tb.save!
    end
  end
end
