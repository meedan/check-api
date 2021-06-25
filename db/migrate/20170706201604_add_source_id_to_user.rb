class AddSourceIdToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :source_id, :integer
    add_index :users, :source_id
    User.find_each do |u|
      s = Source.where(user_id: u.id).first
      u.update_columns(source_id: s.id) unless s.nil?
    end
  end
end
