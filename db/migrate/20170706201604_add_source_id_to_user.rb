class AddSourceIdToUser < ActiveRecord::Migration
  def change
    add_reference :users, :source, index: true, foreign_key: true
    User.find_each do |u|
      s = Source.where(user_id: u.id).first
      u.update_columns(source_id: s.id) unless s.nil?
    end
  end
end
