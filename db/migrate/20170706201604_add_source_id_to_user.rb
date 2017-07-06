class AddSourceIdToUser < ActiveRecord::Migration
  def change
    add_reference :users, :source, index: true, foreign_key: true
    User.find_each do |u|
      s = Source.where(user_id: u.id).first
      u.source_id = s.id
      u.save!
    end
  end
end
