#
# ReindexAlegreWorkspace.perform_async(team_id)
#
# vector_768_ids = File.read("offending_ids_team_id_10.txt").split("\n").collect(&:to_i)
# run_reindex(ProjectMedia.where(id: vector_768_ids), "team_id_10_vector_768_rebuild")

class ReindexAlegreWorkspace
  include Sidekiq::Worker

  sidekiq_options queue: 'alegre', retry: 0

  def perform(team_id, event_id=nil)
    query = get_default_query(team_id)
    event_id ||= Digest::MD5.hexdigest(query.to_sql)
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
    # retrieve the last id processed from environment to allow stateful restart of partially completed jobs
    Rails.cache.read(cache_key(event_id, team_id)) || 0
  end

  def write_last_id(event_id, team_id, pm_id)
    # cache last id processed for team,event pair so we can resume state after failure
    Rails.cache.write(cache_key(event_id, team_id), pm_id)
  end

  def clear_last_id(event_id, team_id)
    # clear job state so that next attempt will start from the beginning
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
    # run a request for all of the configured similarity index types, delete the index and return results to rebuild
    Bot::Alegre::ALL_TEXT_SIMILARITY_FIELDS.each do |field|
      field_value = pm.send(field)
      if !field_value.to_s.empty?
        request_doc = get_request_doc(pm, field, field_value, models)
        request_doc.delete(:model) # TODO: why are we deleting the model element? because deprecated?
        yield request_doc
      end
    end
  end

  def check_for_write(running_bucket, event_id, team_id, write_remains=false, in_processes=3)
    # manage dispatch of documents to bulk similarity api call in parallel
    if running_bucket.length > 500 || write_remains
      log(event_id, 'Writing to Alegre...')
      Parallel.map(running_bucket.each_slice(30).to_a, in_processes: in_processes) { |bucket_slice| Bot::Alegre.request_api('post', '/text/bulk_similarity/', { documents: bucket_slice }) }
      log(event_id, 'Wrote to Alegre.')
      # track state in case job needs to restart
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
    # query by team id to find ProjectMedia that should be reindexed
    # chunk into batches and add to queue
    # manage state by tracking last id processed in case job needs to resume
    log(event_id, "Processing reindex subquery for team #{team_id}")
    query.where(team_id: team_id).where("id > ?", get_last_id(event_id, team_id)).order(:id).find_in_batches(:batch_size => 2500) do |pms|
      pms.each do |pm|
        get_request_docs_for_project_media(pm, models_for_team(team_id)) do |request_doc|
          running_bucket << request_doc
          log(event_id, "Bucket size is #{running_bucket.length}") if running_bucket.length % 50 == 0
          running_bucket = check_for_write(running_bucket, event_id, team_id)
        end
      end
    end
    # make sure to process any leftover items less than batch size
    running_bucket = check_for_write(running_bucket, event_id, team_id, write_remains=true)
    clear_last_id(event_id, team_id)
    running_bucket
  end

  def reindex_project_medias(query, event_id)
    # execute the query, chunk results by team_id, process by team id

    # FIXME: This variable is set but not used
    # started = Time.now.to_i

    running_bucket = []
    log(event_id, "processing reindex query to determine team_ids")
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
