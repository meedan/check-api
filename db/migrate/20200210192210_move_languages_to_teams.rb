class MoveLanguagesToTeams < ActiveRecord::Migration
  def change
    Project.all.select{ |p| !p.get_languages.nil? }.each{ |p|
      p.team.set_languages(p.get_languages)
      p.team.save!
      p.settings.delete(:languages)
      p.save!
    }
  end
end
