class UpdateAlegreStoredProjectMedia < ActiveRecord::Migration
  def change
    count = 0
    Team.find_each do |team|
      ProjectMedia.where(team_id: team.id).find_each do |pm|
        count += 1
        # Bot::Alegre.send_title_to_similarity_index(pm)
        # Bot::Alegre.send_description_to_similarity_index(pm)
      end
    end
  end
end
