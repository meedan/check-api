#
# ReindexAlegreWorkspace.perform_async(team_id)
#
# vector_768_ids = File.read("offending_ids_team_id_10.txt").split("\n").collect(&:to_i)
# ReindexAlegreWorkspace.new.run_reindex(ProjectMedia.where(id: vector_768_ids), "team_id_10_vector_768_rebuild")

class ReindexAlegreWorkspace
  include Sidekiq::Worker

  sidekiq_options queue: 'alegre', retry: 0

  def perform(team_id, event_id=nil)
    query = get_default_query(team_id)
    reindex_event_id ||= Digest::MD5.hexdigest(query.to_sql)
    run_reindex(query, event_id)
  end
  
  def run_reindex(query, event_id)
    log(event_id, 'Preparing reindex event...')
    reindex_project_medias(query, event_id)
    log(event_id, 'Finished reindex event.')
  end
  
  def cache_key(event_id, team_id)
    "check:migrate:reindex_event__#{event_id}_#{team_id}:pm_id"
  end

  def get_last_id(event_id, team_id)
    Rails.cache.read(cache_key(event_id, team_id)) || 0
  end
  
  def write_last_id(event_id, team_id, pm_id)
    Rails.cache.write(cache_key(event_id, team_id), pm_id)
  end
  
  def clear_last_id(event_id, team_id)
    Rails.cache.delete(cache_key(event_id, team_id))
  end
  
  def get_default_query(team_id, last_id=nil)
    ProjectMedia.where("project_medias.id > ? ", last_id.to_i).where(team_id: team_id)
  end

  def get_request_doc(pm, field, field_value, models)
    Bot::Alegre.send_to_text_similarity_index_package(
      pm,
      field,
      field_value,
      Bot::Alegre.item_doc_id(pm, field)
    ).merge(models: models)
  end

  def get_request_docs_for_project_media(pm, models)
    Bot::Alegre::ALL_TEXT_SIMILARITY_FIELDS.each do |field|
      field_value = pm.send(field)
      if !field_value.to_s.empty?
        request_doc = get_request_doc(pm, field, field_value, models)
        request_doc.delete(:model)
        yield request_doc
      end
    end
  end

  def check_for_write(running_bucket, event_id, team_id, write_remains=false)
    if running_bucket.length > 500 || write_remains
      Parallel.map(running_bucket.each_slice(30).to_a, in_processes: 3) do |bucket_slice|
        Bot::Alegre.request_api('post', '/text/bulk_similarity/', { documents: bucket_slice })
      end
      write_last_id(event_id, team_id, running_bucket.last[:context][:project_media_id])
      running_bucket = []
    end
    running_bucket
  end

  def models_for_team(team_id)
    [
      Bot::Alegre.get_alegre_tbi(team_id).get_alegre_model_in_use,
      Bot::Alegre::ELASTICSEARCH_MODEL
    ].compact.uniq
  end

  def process_team(running_bucket, team_id, query, event_id)
    last_id = get_last_id(event_id, team_id)
    query.where(team_id: team_id).order(:id).find_in_batches(:batch_size => 2500) do |pms|
      pms.each do |pm|
        get_request_docs_for_project_media(pm, models_for_team(team_id)) do |request_doc|
          running_bucket << request_doc
        end
      end
      running_bucket = check_for_write(running_bucket, event_id, team_id)
    end
    running_bucket = check_for_write(running_bucket, event_id, team_id, true)
    clear_last_id(event_id, team_id)
    running_bucket
  end

  def reindex_project_medias(query, event_id)
    started = Time.now.to_i
    running_bucket = []
    query.distinct.pluck(:team_id).each do |team_id|
      running_bucket = process_team(running_bucket, team_id, query, event_id)
    end
    running_bucket
  end

  private

  def log(event_id, message)
    Rails.logger.info "[Alegre Bot] [Reindex] [Event #{event_id}] [#{Time.now}] #{message}"
  end
end

