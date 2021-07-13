class SetTasksEnabledForTeams < ActiveRecord::Migration
  def change
    Team.find_each do |t|
      begin
        t.set_tasks_enabled = true
        t.save!
        puts "Successfully set_tasks_enabled for team #{t.slug}"
      rescue
        puts "Could not set_tasks_enabled for team #{t.slug}"
      end
    end
  end
end
