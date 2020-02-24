namespace :check do
  namespace :migrate do
    task delete_smooch_bot_comments: :environment do
    	smooch_bot = BotUser.where(login: 'smooch').last.id
    	index_alias = CheckElasticSearchModel.get_index_alias
      client = MediaSearch.gateway.client
    	Annotation.where(annotation_type: 'comment').joins("INNER JOIN project_medias pm ON pm.id = annotations.annotated_id AND annotations.annotated_type = 'ProjectMedia'")
    	.where('pm.user_id' => smooch_bot).find_in_batches(:batch_size => 5000) do |comments|
        es_body = []
        pm_comments = {}
        comments.each do |c|
          pm_comments[c.annotated_id] = [] if pm_comments[c.annotated_id].nil?
          pm_comments[c.annotated_id] << c.id
        end
        pm_comments.each do |pm, ids|
          print "."
          doc_id = Base64.encode64("ProjectMedia/#{pm}")
          script = "for (int i = 0; i < ctx._source.comments.size(); i++) { if(params.ids.contains(ctx._source.comments[i].id)){ctx._source.comments.remove(i);}}"      
          data = { script: { source: script, params: { ids: ids } } }
          es_body << { update: { _index: index_alias, _type: 'media_search', _id: doc_id, retry_on_conflict: 3, data: data } }
        end
    		Comment.where(id: comments.map(&:id)).delete_all
        client.bulk body: es_body unless es_body.blank?  
    	end
    end
  end
end
