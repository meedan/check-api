class MigrateEsOriginalEmbedData < ActiveRecord::Migration[4.2]
  def change
  	ProjectMedia.joins(:media).where('medias.type=?', 'Link').find_each do |pm|
  		em = pm.get_annotations('embed').last
  		unless em.nil?
  			em = em.load
  			em.update_elasticsearch_embed
  		end
  	end
  end
end
