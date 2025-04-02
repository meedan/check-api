require 'active_support/concern'
class AlegreTimeoutError < StandardError; end
class TemporaryProjectMedia
  attr_accessor :team_id, :id, :url, :text, :type, :field
  def media
    media_type_map = {
      "claim" => "Claim",
      "link" => "Link",
      "image" => "UploadedImage",
      "video" => "UploadedVideo",
      "audio" => "UploadedAudio",
    }
    Struct.new(:type).new(media_type_map[type])
  end

  def is_blank?
    self.type == "blank"
  end

  def is_link?
    self.type == "link"
  end

  def is_text?
    self.type == "text"
  end

  def is_image?
    self.type == "image"
  end

  def is_video?
    self.type == "video"
  end

  def is_audio?
    self.type == "audio"
  end

  def is_uploaded_media?
    self.is_image? || self.is_audio? || self.is_video?
  end
end

module AlegreV2
  extend ActiveSupport::Concern

  module ClassMethods
    def host
      CheckConfig.get('alegre_host')
    end

    def sync_path(project_media)
      self.sync_path_for_type(get_type(project_media))
    end

    def sync_path_for_type(type)
      "/similarity/sync/#{type}"
    end

    def async_path(project_media)
      self.async_path_for_type(get_type(project_media))
    end

    def async_path_for_type(type)
      "/similarity/async/#{type}"
    end

    def delete_path(project_media)
      self.delete_path_for_type(get_type(project_media))
    end

    def delete_path_for_type(type)
      "/#{type}/similarity/"
    end

    def release_db
      if RequestStore.store[:pause_database_connection]
        ActiveRecord::Base.clear_active_connections!
        ActiveRecord::Base.connection.close
      end
    end

    def reconnect_db
      ActiveRecord::Base.connection.reconnect! if RequestStore.store[:pause_database_connection]
    end

    def get_request_object(method, _path, uri)
      full_path = uri.path
      full_path += "?#{uri.query}" if uri.query
      headers = ["post", "delete"].include?(method.downcase)  ? {'Content-Type' => 'application/json'} : {}
      return ('Net::HTTP::' + method.capitalize).constantize.new(full_path, headers)
    end

    def generate_request(method, path, params)
      uri = URI(host + path)
      request = get_request_object(method, path, uri)
      if method.downcase == 'post' || method.downcase == 'delete'
        request.body = params.to_json
      end
      http = Net::HTTP.new(uri.hostname, uri.port)
      http.use_ssl = uri.scheme == 'https'
      return http, request
    end

    def run_request(http, request)
      http.request(request)
    end

    def parse_response(http, request)
      release_db
      response = run_request(http, request)
      response_body = response.body
      Rails.logger.info("[Alegre Bot] Alegre Bot response and body: (#{response.inspect}, #{response_body})")
      reconnect_db
      JSON.parse(response_body)
    end

    def request(method, path, params, retries=3)
      http, request = generate_request(method, path, params)
      begin
        Rails.logger.info("[Alegre Bot] Alegre Bot request: (#{method}, #{path}, #{params.inspect}, #{retries})")
        parsed_response = parse_response(http, request)
        Rails.logger.info("[Alegre Bot] Alegre response: #{parsed_response.inspect}")
        parsed_response
      rescue StandardError => e
        Rails.logger.error("[Alegre Bot] Alegre error: (#{method}, #{path}, #{params.inspect}, #{retries}), #{e.inspect} #{e.message}")
        CheckSentry.notify(e, bot: 'alegre', method: method, path: path, params: params, retries: retries)
        if retries > 0
          sleep 1
          self.request(method, path, params, retries - 1)
        end
        { 'type' => 'error', 'data' => { 'message' => e.message } }
      end
    end

    def request_delete_from_raw(params, type)
      request("delete", delete_path_for_type(type), params)
    end

    def request_delete(data, project_media)
      request("delete", delete_path(project_media), data)
    end

    def request_sync(data, project_media)
      request("post", sync_path(project_media), data)
    end

    def request_async(data, project_media)
      request("post", async_path(project_media), data)
    end

    def get_type(project_media)
      type = nil
      if project_media.is_text?
        type = 'text'
      elsif project_media.is_image?
        type = 'image'
      elsif project_media.is_video?
        type = 'video'
      elsif project_media.is_audio?
        type = 'audio'
      end
      type
    end

    def content_hash_for_value(value)
      value.nil? ? nil : Digest::MD5.hexdigest(value)
    end

    def content_hash(project_media, field)
      if Bot::Alegre::ALL_TEXT_SIMILARITY_FIELDS.include?(field)
        content_hash_for_value(project_media.send(field))
      elsif project_media.is_link?
        return content_hash_for_value(project_media.media.url)
      elsif project_media.is_a?(TemporaryProjectMedia)
        return Rails.cache.read("url_sha:#{project_media.url}")
      elsif project_media.is_uploaded_media?
        return project_media.media.file.filename.split(".").first
      else
        return content_hash_for_value(project_media.send(field).to_s)
      end
    end

    def generic_package(project_media, field)
      content_hash_value = content_hash(project_media, field)
      params = {
        doc_id: item_doc_id(project_media, field),
        context: get_context(project_media, field)
      }
      params[:content_hash] = content_hash_value if !content_hash_value.nil?
      params
    end

    def delete_package(project_media, field, params={}, quiet=false)
      type = get_type(project_media)
      return if type.blank?
      generic_package(project_media, field).merge(
        self.send("delete_package_#{type}", project_media, field, params)
      ).merge(
        quiet: quiet
      ).merge(params)
    end

    def generic_package_text(project_media, field, params, fuzzy=false, match_across_content_types=true)
      package = generic_package(project_media, field).merge(
        params
      ).merge(
        models: self.indexing_models_to_use(project_media),
        text: project_media.send(field),
        fuzzy: fuzzy == 'true' || fuzzy.to_i == 1,
        match_across_content_types: match_across_content_types,
      )
      team_id = project_media.team_id
      language = self.language_for_similarity(team_id)
      package[:language] = language if !language.nil?
      package[:min_es_score] = self.get_min_es_score(team_id)
      package
    end

    def delete_package_text(project_media, field, params)
      generic_package_text(project_media, field, params)
    end

    def generic_package_media(project_media, params)
      generic_package(project_media, nil).merge(
        url: media_file_url(project_media),
      ).merge(params)
    end

    def generic_package_video(project_media, params)
      generic_package_media(project_media, params)
    end

    def delete_package_video(project_media, _field, params)
      generic_package_video(project_media, params)
    end

    def generic_package_image(project_media, params)
      generic_package_media(project_media, params)
    end

    def delete_package_image(project_media, _field, params)
      generic_package_image(project_media, params)
    end

    def generic_package_audio(project_media, params)
      generic_package_media(project_media, params)
    end

    def delete_package_audio(project_media, _field, params)
      generic_package_audio(project_media, params)
    end

    def store_package(project_media, field, params={})
      type = get_type(project_media)
      return if type.nil?
      generic_package(project_media, field).merge(
        self.send("store_package_#{type}", project_media, field, params)
      )
    end

    def is_not_generic_field(field)
      !["audio", "video", "image"].include?(field)
    end

    def get_context(project_media, field=nil)
      context = {
        team_id: project_media.team_id,
        project_media_id: project_media.id,
        has_custom_id: true
      }
      context[:field] = field if field && is_not_generic_field(field)
      context[:temporary_media] = project_media.is_a?(TemporaryProjectMedia)
      context
    end

    def store_package_video(project_media, _field, params)
      generic_package_video(project_media, params)
    end

    def store_package_image(project_media, _field, params)
      generic_package_image(project_media, params)
    end

    def store_package_audio(project_media, _field, params)
      generic_package_audio(project_media, params)
    end

    def store_package_text(project_media, field, params)
      generic_package_text(project_media, field, params)
    end

    def index_async_with_params(params, type, suppress_search_response=true)
      request("post", async_path_for_type(type), params.merge(suppress_search_response: suppress_search_response))
    end

    def index_sync_with_params(params, type)
      query_sync_with_params(params, type)
    end

    def query_sync_with_params(params, type)
      request("post", sync_path_for_type(type), params)
    end

    def query_async_with_params(params, type)
      request("post", async_path_for_type(type), params)
    end

    def get_sync(project_media, field=nil, params={})
      request_sync(
        store_package(project_media, field, params),
        project_media
      )
    end

    def get_async(project_media, field=nil, params={})
      request_async(
        store_package(project_media, field, params),
        project_media
      )
    end

    def delete(project_media, field=nil, params={})
      request_delete(
        delete_package(project_media, field, params),
        project_media
      )
    rescue StandardError => e
      error = Bot::Alegre::Error.new(e)
      Rails.logger.error("[Alegre Bot] Exception on Delete for ProjectMedia ##{project_media.id}: #{error.class} - #{error.message}")
      CheckSentry.notify(error, bot: "alegre", project_media: project_media, params: params, field: field)
    end

    def get_per_model_threshold(project_media, threshold)
      type = get_type(project_media)
      if type == "text"
        { per_model_threshold: threshold&.collect{ |x| { model: x[:model], value: x[:value] } } }
      else
        { threshold: threshold&.dig(0, :value) }
      end
    end

    def isolate_relevant_context(project_media, result)
      (result["contexts"]||result["context"]).select{|x| ([x["team_id"]].flatten & [project_media.team_id].flatten).count > 0 && !x["temporary_media"]}.first
    end

    def get_target_field(project_media, field)
      type = get_type(project_media)
      return field if type == "text"
      return type if !type.nil?
      field || type
    end

    def parse_similarity_results(project_media, field, results, relationship_type)
      results ||= []
      Hash[results.collect{|result|
        result["context"] = isolate_relevant_context(project_media, result)
        [
          result["context"] && result["context"]["project_media_id"],
          {
            score: result["score"],
            context: result["context"],
            model: result["model"],
            source_field: get_target_field(project_media, field),
            target_field: get_target_field(project_media, result["field"] || result.dig("context", "field")),
            relationship_type: relationship_type
          }
        ]
      }.reject{ |k,_| k == project_media.id }]
    end

    def safe_get_async(project_media, field, params={})
      response = get_async(project_media, field, params)
      retries = 0
      while response.nil? && retries < 3
        response = get_async(project_media, field, params)
        retries += 1
      end
      response
    end

    def safe_get_sync(project_media, field, params={})
      response = get_sync(project_media, field, params)
      retries = 0
      while (response.nil? || response["result"].nil?) && retries < 3
        response = get_sync(project_media, field, params)
        retries += 1
      end
      response
    end

    def cache_items_via_callback(project_media, field, confirmed, results)
      relationship_type = confirmed ? Relationship.confirmed_type : Relationship.suggested_type
      parse_similarity_results(
        project_media,
        field,
        results,
        relationship_type
      )
    end

    def get_items(project_media, field, confirmed=false, initial_threshold=nil)
      relationship_type = confirmed ? Relationship.confirmed_type : Relationship.suggested_type
      type = get_type(project_media)
      if type=="text" && Alegre::BOT::BAD_TITLE_REGEX =~ project_media.send(field)
        return {}
      end
      if initial_threshold.nil?
        initial_threshold = get_threshold_for_query(type, project_media, confirmed)
      end
      threshold = get_per_model_threshold(project_media, initial_threshold)
      parse_similarity_results(
        project_media,
        field,
        safe_get_sync(project_media, field, threshold)["result"],
        relationship_type
      )
    end

    def get_items_async(project_media, field, confirmed=false, initial_threshold=nil)
      type = get_type(project_media)
      if type=="text" && Alegre::BOT::BAD_TITLE_REGEX =~ project_media.send(field)
        return {}
      end
      if initial_threshold.nil?
        initial_threshold = get_threshold_for_query(type, project_media, confirmed)
      end
      threshold = get_per_model_threshold(project_media, initial_threshold)
      safe_get_async(project_media, field, threshold.merge(confirmed: confirmed))
    end

    def get_suggested_items(project_media, field, threshold=nil)
      get_items(project_media, field, false, threshold)
    end

    def get_confirmed_items(project_media, field, threshold=nil)
      get_items(project_media, field, true, threshold)
    end

    def get_suggested_items_async(project_media, field, threshold=nil)
      get_items_async(project_media, field, false, threshold)
    end

    def get_confirmed_items_async(project_media, field, threshold=nil)
      get_items_async(project_media, field, true, threshold)
    end

    def get_similar_items_v2(project_media, field, threshold=nil)
      if similarity_disabled_for_project_media?(project_media)
        {}
      else
        suggested_or_confirmed = get_suggested_items(project_media, field, threshold)
        confirmed = get_confirmed_items(project_media, field, threshold)
        merge_suggested_and_confirmed(suggested_or_confirmed, confirmed, project_media)
      end
    end

    def similarity_disabled_for_project_media?(project_media)
      type = Bot::Alegre.get_type(project_media)
      !should_get_similar_items_of_type?('master', project_media.team_id) || !should_get_similar_items_of_type?(type, project_media.team_id)
    end

    def get_similar_items_v2_async(project_media, field, threshold=nil)
      if similarity_disabled_for_project_media?(project_media)
        return false
      else
        get_suggested_items_async(project_media, field, threshold)
        get_confirmed_items_async(project_media, field, threshold)
        return true
      end
    end

    def get_required_keys(project_media, field)
      {
        confirmed_results: "alegre:async_results:#{project_media.id}_#{field}_true",
        suggested_or_confirmed_results: "alegre:async_results:#{project_media.id}_#{field}_false"
      }
    end

    def get_parsed_cached_data_for_key(key)
      value = Redis.new(REDIS_CONFIG).get(key)
      Hash[YAML.load(value).collect{|kk,vv| [kk.to_i, vv]}] if value
    end

    def get_cached_data(required_keys)
      # For a given project media, we expect a set of keys to be set by the webhook callbacks sent from alegre back to check-api.
      # For each callback response (which is set via #process_alegre_callback), we store the value as serialized YAML to persist
      # the data such that symbolized keys return as symbols (as opposed to JSON, which loses the distinction). Here, in effect,
      # we check to see if all the responses we expect from Alegre have been sent - downstream of this, we check to see if all
      # responses are non-empty before proceeding to creating relationships.
      Hash[required_keys.collect{|k,v| [k, get_parsed_cached_data_for_key(v)]}]
    end

    def get_similar_items_v2_callback(project_media, field)
      if similarity_disabled_for_project_media?(project_media)
        return {}
      else
        cached_data = get_cached_data(get_required_keys(project_media, field))
        if !cached_data.values.include?(nil)
          suggested_or_confirmed = cached_data[:suggested_or_confirmed_results]
          confirmed = cached_data[:confirmed_results]
          merge_suggested_and_confirmed(suggested_or_confirmed, confirmed, project_media)
        end
      end
    end

    def relate_project_media(project_media, field=nil)
      self.add_relationships(project_media, self.get_similar_items_v2(project_media, field)) unless project_media.is_blank?
    end

    def relate_project_media_async(project_media, field=nil)
      self.get_similar_items_v2_async(project_media, field) unless project_media.is_blank?
    end

    def relate_project_media_callback(project_media, field=nil)
      self.add_relationships(project_media, get_similar_items_v2_callback(project_media, field)) unless project_media.is_blank?
    end

    def is_cached_data_not_good(cached_data)
      cached_data.values.collect{|x| x.nil?}.include?(true)
    end

    def wait_for_results(project_media, args)
      return {} if similarity_disabled_for_project_media?(project_media)
      cached_data = get_cached_data(get_required_keys(project_media, nil))
      timeout = args[:timeout] || CheckConfig.get('alegre_timeout', 120, :integer).to_f
      start_time = Time.now
      while start_time + timeout > Time.now && is_cached_data_not_good(cached_data) #more robust for any type of null response
        sleep(1)
        cached_data = get_cached_data(get_required_keys(project_media, nil))
      end
      CheckSentry.notify(AlegreTimeoutError.new('Timeout when waiting for async response from Alegre'), params: args.merge({ cached_data: cached_data }).merge({time: Time.now, start_time: start_time, timeout: timeout})) if start_time + timeout < Time.now
      return cached_data
    end

    def get_items_with_similar_media_v2(args={})
      text = args[:text]
      field = args[:field]
      media_url = args[:media_url]
      project_media = args[:project_media]
      threshold = args[:threshold]
      team_ids = args[:team_ids]
      type = args[:type]
      if project_media.nil?
        project_media = TemporaryProjectMedia.new
        project_media.text = text
        project_media.field = field
        project_media.url = media_url
        project_media.id = Digest::MD5.hexdigest(project_media.url).to_i(16)
        project_media.team_id = team_ids
        project_media.type = type
      end
      get_similar_items_v2_async(project_media, nil, threshold)
      wait_for_results(project_media, args)
      response = get_similar_items_v2_callback(project_media, nil)
      delete(project_media, nil) if project_media.is_a?(TemporaryProjectMedia)
      return response
    end

    def process_alegre_callback(params)
      redis = Redis.new(REDIS_CONFIG)
      project_media = ProjectMedia.find(params.dig('data', 'item', 'raw', 'context', 'project_media_id')) rescue nil
      should_relate = true
      if project_media.nil?
        project_media = TemporaryProjectMedia.new
        project_media.text = params.dig('data', 'item', 'raw', 'text')
        project_media.url = params.dig('data', 'item', 'raw', 'url')
        project_media.id = params.dig('data', 'item', 'raw', 'context', 'project_media_id')
        project_media.team_id = params.dig('data', 'item', 'raw', 'context', 'team_id')
        project_media.field = params.dig('data', 'item', 'raw', 'context', 'field')
        project_media.type = params['model_type']
        should_relate = false
      end
      confirmed = params.dig('data', 'item', 'raw', 'confirmed')
      field = params.dig('data', 'item', 'raw', 'context', 'field')
      access_key = confirmed ? :confirmed_results : :suggested_or_confirmed_results
      key = get_required_keys(project_media, field)[access_key]
      response = cache_items_via_callback(project_media, field, confirmed, params.dig('data', 'results', 'result').dup) #dup so we can better debug when playing with this in a repl
      redis.set(key, response.to_yaml)
      redis.expire(key, 1.day.to_i)
      relate_project_media_callback(project_media, field) if should_relate
    end

    def restrict_contexts(project_media, project_media_id_scores)
      Hash[project_media_id_scores.collect{|project_media_id, response_data|
        [
          project_media_id,
          response_data.merge(context: [response_data[:context]].flatten.select{|c| c.with_indifferent_access[:team_id] == project_media.team_id})
        ]
      }]
    end
  end
end
