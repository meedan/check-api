namespace :check do
  namespace :migrate do
    desc "Delete comments that were created by Smooch bot"
    task delete_smooch_bot_comments: :environment do
      smooch_bot = BotUser.where(login: 'smooch').last
      Comment.where(annotation_type: 'comment', annotator_type: [smooch_bot.class.name, nil], annotator_id: [smooch_bot.id, nil])
      .joins("INNER JOIN project_medias pm ON pm.id = annotations.annotated_id AND annotations.annotated_type = 'ProjectMedia'")
      .where('pm.user_id' => smooch_bot.id)
      .find_in_batches(:batch_size => 2500) do |comments|
        comments.each do |c|
          print "."
          c.annotation_versions.delete_all
        end
        Comment.where(id: comments.map(&:id)).delete_all
      end
    end

    desc "Delete comments that created by Alegre bot and update Alegre requests with Smooch bot"
    task delete_alegre_bot_comments: :environment do
      alegre_bot = BotUser.where(login: 'alegre').last
      smooch_bot = BotUser.where(login: 'smooch').last
      # delete alegre comments
      Comment.where(annotation_type: 'comment', annotator_type: alegre_bot.class.name, annotator_id: alegre_bot.id)
      .find_in_batches(:batch_size => 2500) do |comments|
        comments.each do |c|
          print "."
          c.annotation_versions.delete_all
        end
        Comment.where(id: comments.map(&:id)).delete_all
      end
      # Change annotator from Alegre to Smooch for smooch data annotations
      ProjectMedia.where(user_id: smooch_bot.id).find_in_batches(:batch_size => 2500) do |pms|
        pms.each do |pm|
          print "."
          logs = pm.get_versions_log(['create_dynamicannotationfield'], ['smooch_data'], [], [alegre_bot.login])
          logs.update_all(whodunnit: smooch_bot.id)
        end
      end
    end

    desc "re-index comments for smooch bot medias"
    task reindex_smooch_medias_comments: :environment do
      index_alias = CheckElasticSearchModel.get_index_alias
      client = MediaSearch.gateway.client
      smooch_bot = BotUser.where(login: 'smooch').last
      ProjectMedia.where(user_id: smooch_bot.id).find_in_batches(:batch_size => 2500) do |pms|
        es_body = []
        pms.each do |pm|
          print "."
          comments = pm.annotations('comment')
          doc_id = pm.get_es_doc_id(pm)
          fields = { 'comments' => comments }
          es_body << { update: { _index: index_alias, _type: 'media_search', _id: doc_id, retry_on_conflict: 3, data: { doc: fields } } }
        end
        client.bulk body: es_body unless es_body.blank?
      end
    end
  end
end
