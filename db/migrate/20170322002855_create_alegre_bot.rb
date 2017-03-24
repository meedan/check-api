class CreateAlegreBot < ActiveRecord::Migration
  def change
    bot = Bot::Alegre.new
    bot.name = 'Alegre Bot'
    bot.save!
  end
end
