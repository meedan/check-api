class AddRelationshipWeight < ActiveRecord::Migration
  def change
    add_column :relationships, :weight, :float, default: 0, null: false
  end
end
