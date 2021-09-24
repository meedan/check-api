class RemoveLimits < ActiveRecord::Migration[4.2]
  def change
    if column_exists?(:teams, :limits)
      Team.find_each do |team|
        next if team.limits.blank?
        limits = YAML.load(team.limits).with_indifferent_access
        if limits.has_key?('max_number_of_members')
          team.set_max_number_of_members(limits['max_number_of_members'])
          team.save(validate: false)
        end
      end
      remove_column :teams, :limits
    end
  end
end
