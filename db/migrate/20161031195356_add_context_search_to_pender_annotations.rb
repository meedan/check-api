class AddContextSearchToPenderAnnotations < ActiveRecord::Migration[4.2]
  def change
    Media.all.each do |m|
      search_context = []
      m.project_medias.each do |pm|
        embed = m.annotations('embed', pm.project).last
        search_context << pm.project.id if embed.nil?
      end
      em_none = m.annotations('embed', 'none').last
      unless em_none.nil? or search_context.blank?
        em_none.search_context = search_context
        em_none.save!
      end
    end
  end
end
