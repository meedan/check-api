class Bot::Viber < BotUser
end
class Bot::Facebook < BotUser
end
class Bot::Twitter < BotUser
end
class Bot::BridgeReader < BotUser
end

class RemoveBridgeContent < ActiveRecord::Migration[4.2]
  def change
    bot_types = ['Bot::Viber', 'Bot::Facebook', 'Bot::Twitter', 'Bot::BridgeReader']
    User.where('type in (?)', bot_types).destroy_all
    bot_names = ['Viber Bot', 'Facebook Bot', 'Twitter Bot', 'Bridge Reader Bot']
    Source.where('name in (?)', bot_names).destroy_all
  end
end
