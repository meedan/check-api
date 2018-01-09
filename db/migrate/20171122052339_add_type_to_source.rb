class AddTypeToSource < ActiveRecord::Migration
  def change
  	add_column :sources, :type, :string
  	Source.where.not(team_id: nil).update_all(type: 'Source')
  	Source.where(team_id: nil).update_all(type: 'Profile')
  end
end
