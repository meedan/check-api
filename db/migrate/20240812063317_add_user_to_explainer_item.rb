class AddUserToExplainerItem < ActiveRecord::Migration[6.1]
  def change
    add_reference(:explainer_items, :user, foreign_key: true, null: true)
  end
end
