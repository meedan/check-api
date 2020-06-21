class AddLanguagesToTeamReportSettings < ActiveRecord::Migration
  def change
    Team.find_each do |team|
      settings = team.settings || {}
      settings = settings.with_indifferent_access
      if settings.has_key?('disclaimer') || settings.has_key?('introduction') || settings.has_key?('use_introduction') || settings.has_key?('use_disclaimer') 
        puts "[#{Time.now}] Updating team #{team.name}..."
        new_settings = settings.clone
        disclaimer = new_settings.delete('disclaimer')
        introduction = new_settings.delete('introduction')
        use_disclaimer = new_settings.delete('use_disclaimer')
        use_introduction = new_settings.delete('use_introduction')
        language = team.get_language || 'en'
        new_settings[:report] = {}
        new_settings[:report][language] = {
          disclaimer: disclaimer,
          introduction: introduction,
          use_disclaimer: use_disclaimer,
          use_introduction: use_introduction
        }
        team.settings = new_settings
        team.save!
      end
    end
  end
end
