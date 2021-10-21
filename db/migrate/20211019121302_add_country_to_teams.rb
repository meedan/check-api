class AddCountryToTeams < ActiveRecord::Migration[5.2]
  def change
    add_column :teams, :country, :string
    add_index :teams, :country
  end
end
