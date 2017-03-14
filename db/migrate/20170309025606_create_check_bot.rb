class CreateCheckBot < ActiveRecord::Migration
  def up
    b = Bot.new
    b.name = 'Check Bot'
    b.save!
  end

  def down
    b = Bot.where(name: 'Check Bot').last
    b.destroy unless b.nil?
  end
end
