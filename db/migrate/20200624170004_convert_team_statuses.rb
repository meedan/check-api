class ConvertTeamStatuses < ActiveRecord::Migration
  def change
    Team.find_each do |team|
      settings = team.settings || {}
      settings = settings.with_indifferent_access
      if settings.has_key?('media_verification_statuses')
        puts "Updating verification statuses for team #{team.name}..."
        begin
          statuses = settings.with_indifferent_access[:media_verification_statuses]
          next if statuses.blank? || statuses[:statuses].blank?
          statuses[:active] ||= statuses[:default]
          team.get_media_verification_statuses[:statuses].each_with_index do |status, i|
            statuses[:statuses][i] = {
              id: status[:id],
              style: status['style'],
              locales: {
                en: {
                  label: status['label'],
                  description: status['description']
                }
              }
            }
          end
          team.set_media_verification_statuses = statuses
          team.save!
        rescue
          puts "Team #{team.name} already had invalid status setting... you'll need to fix it manually."
        end
      end
    end
  end
end
