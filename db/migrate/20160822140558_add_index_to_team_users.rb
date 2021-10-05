class AddIndexToTeamUsers < ActiveRecord::Migration[4.2]
  def change

    tu = TeamUser.all.group_by { |x| [x.team_id, x.user_id] }
    tu.each do |key, value|
      value.each_with_index do |row, index|
        unless value.length == 1
          if index == value.length - 1
            row.destroy
          end
        end
      end
    end

    add_index :team_users, [:team_id, :user_id], unique: true
  end
end
