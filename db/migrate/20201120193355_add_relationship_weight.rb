class AddRelationshipWeight < ActiveRecord::Migration[4.2]
  def change
    add_column :relationships, :weight, :float, default: 0
  end
end
