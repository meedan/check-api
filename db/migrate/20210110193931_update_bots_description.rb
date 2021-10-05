class UpdateBotsDescription < ActiveRecord::Migration[4.2]
  def change
    b = BotUser.smooch_user
    unless b.nil?
      b.set_description = 'Connect Check with Facebook Messenger, WhatsApp and Twitter to create tiplines.'
      b.save!
    end
    b = BotUser.keep_user
    unless b.nil?
      b.set_description = 'Archive links to third-party archiving services.'
      b.save!
    end
  end
end
