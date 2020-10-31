namespace :check do
  namespace :migrate do
    task links_published_at: :environment do
      started = Time.now.to_i
      start_from = 0
      errors = 0
      index_alias = CheckElasticSearchModel.get_index_alias
      client = $repository.client
      all_pms = ProjectMedia.joins(:media).where('medias.type' => 'Link').order('id ASC').where('project_medias.id > ?', start_from)
      progressbar = ProgressBar.create(:total => all_pms.count)
      last = 0
      all_pms.find_in_batches(:batch_size => 3000) do |pms|
        progressbar.increment
        es_body = []
        pms.each do |pm|
          doc_id = pm.get_es_doc_id(pm)
          fields = { 'published_at' => pm.published_at }
          es_body << { update: { _index: index_alias, _id: doc_id, data: { doc: fields } } }
          last = pm.id if pm.id > last
        end
        response = client.bulk body: es_body
        puts "[#{Time.now}] Done until project media with ID #{last}"
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes. Errors: #{errors}"
    end
  end
end
