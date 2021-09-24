class ConvertTeamSuggestedTagsToTagText < ActiveRecord::Migration[4.2]
  def change
    Team.find_each do |team|
      suggested_tags = team.settings[:suggested_tags] || team.settings['suggested_tags']
      suggested_tags.to_s.split(',').each do |text|
        text = text.strip.gsub(/^#/, '')
        tag_text = TagText.where(text: text, team_id: team.id).last
        if tag_text.nil?
          TagText.create!(text: text, team_id: team.id, teamwide: true)
        else
          tag_text.update_column(:teamwide, true)
        end
      end
    end
  end
end
