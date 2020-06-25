class ConvertTeamStatuses < ActiveRecord::Migration
  def change
    Team.find_each do |team|
      settings = team.settings || {}
      settings = settings.with_indifferent_access
      if settings.has_key?('media_verification_statuses')
        puts "Updating verification statuses for team #{team.name}..."
        begin
          statuses = settings[:media_verification_statuses]
          new_statuses = statuses.clone
          next if statuses.blank? || statuses[:statuses].blank?
          new_statuses[:active] ||= statuses[:default]
          statuses[:statuses].each_with_index do |status, i|
            new_statuses[:statuses][i] = {
              id: status[:id],
              style: status[:style],
              locales: {
                en: {
                  label: status[:label],
                  description: status[:description].to_s
                }
              }
            }
          end
          team.set_media_verification_statuses = new_statuses
          team.save!
        rescue StandardError => e
          puts "Team #{team.name} already had invalid status setting... you'll need to fix it manually. The error was: #{e.message}"
        end
      end
    end
  end
end
