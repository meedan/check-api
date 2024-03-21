require 'active_support/concern'

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
      "/similarity/async/#{get_type(project_media)}"
    end

    def delete_path(project_media)
      type = get_type(project_media)
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
        if retries > 0
          sleep 1
          self.request(method, path, params, retries - 1)
        end
        Rails.logger.error("[Alegre Bot] Alegre error: (#{method}, #{path}, #{params.inspect}, #{retries}), #{e.inspect} #{e.message}")
        { 'type' => 'error', 'data' => { 'message' => e.message } }
      end
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

    def generic_package(project_media, field)
      {
        doc_id: item_doc_id(project_media, field),
        context: get_context(project_media, field)
      }
    end

    def delete_package(project_media, field, params={}, quiet=false)
      generic_package(project_media, field).merge(
        self.send("delete_package_#{get_type(project_media)}", project_media, field, params)
      ).merge(
        quiet: quiet
      ).merge(params)
    end

    def generic_package_media(project_media, params)
      generic_package(project_media, nil).merge(
        url: media_file_url(project_media),
      ).merge(params)
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
      generic_package(project_media, field).merge(
        self.send("store_package_#{get_type(project_media)}", project_media, field, params)
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
      context
    end

    def store_package_image(project_media, _field, params)
      generic_package_image(project_media, params)
    end

    def store_package_audio(project_media, _field, params)
      generic_package_audio(project_media, params)
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
      result["context"].select{|x| x["team_id"] == project_media.team_id}.first
    end

    def get_target_field(project_media, field)
      type = get_type(project_media)
      return field if type == "text"
      return type if !type.nil?
      field || type
    end

    def parse_similarity_results(project_media, field, results, relationship_type)
      Hash[results.collect{|result|
        result["context"] = Bot::Alegre.isolate_relevant_context(project_media, result)
        [
          result["context"] && result["context"]["project_media_id"],
          {
            score: result["score"],
            context: result["context"],
            model: result["model"],
            source_field: Bot::Alegre.get_target_field(project_media, field),
            target_field: Bot::Alegre.get_target_field(project_media, result["field"]),
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
      type = Bot::Alegre.get_type(project_media)
      Bot::Alegre.parse_similarity_results(
        project_media,
        field,
        results,
        relationship_type
      )
    end

    def get_items(project_media, field, confirmed=false)
      relationship_type = confirmed ? Relationship.confirmed_type : Relationship.suggested_type
      type = get_type(project_media)
      threshold = get_per_model_threshold(project_media, Bot::Alegre.get_threshold_for_query(type, project_media, confirmed))
      parse_similarity_results(
        project_media,
        field,
        safe_get_sync(project_media, field, threshold)["result"],
        relationship_type
      )
    end

    def get_items_async(project_media, field, confirmed=false)
      type = get_type(project_media)
      threshold = get_per_model_threshold(project_media, Bot::Alegre.get_threshold_for_query(type, project_media, confirmed))
      safe_get_async(project_media, field, threshold.merge(confirmed: confirmed))
    end

    def get_suggested_items(project_media, field)
      get_items(project_media, field)
    end

    def get_confirmed_items(project_media, field)
      get_items(project_media, field, true)
    end

    def get_suggested_items_async(project_media, field)
      get_items_async(project_media, field)
    end

    def get_confirmed_items_async(project_media, field)
      get_items_async(project_media, field, true)
    end

    def get_similar_items_v2(project_media, field)
      type = get_type(project_media)
      if !Bot::Alegre.should_get_similar_items_of_type?('master', project_media.team_id) || !Bot::Alegre.should_get_similar_items_of_type?(type, project_media.team_id)
        {}
      else
        suggested_or_confirmed = get_suggested_items(project_media, field)
        confirmed = get_confirmed_items(project_media, field)
        Bot::Alegre.merge_suggested_and_confirmed(suggested_or_confirmed, confirmed, project_media)
      end
    end

    def get_similar_items_v2_async(project_media, field)
      type = get_type(project_media)
      if !Bot::Alegre.should_get_similar_items_of_type?('master', project_media.team_id) || !Bot::Alegre.should_get_similar_items_of_type?(type, project_media.team_id)
        return false
      else
        get_suggested_items_async(project_media, field)
        get_confirmed_items_async(project_media, field)
        return true
      end
    end

    def get_required_keys(project_media, field)
      {
        confirmed_results: "alegre:async_results:#{project_media.id}_#{field}_true",
        suggested_or_confirmed_results: "alegre:async_results:#{project_media.id}_#{field}_false"
      }
    end

    def get_cached_data(required_keys)
      redis = Redis.new(REDIS_CONFIG)
      Hash[required_keys.collect{|k,v| [k, (Hash[JSON.parse(redis.get(v)).collect{|kk,vv| [kk.to_i, vv]}] rescue [])]}]
    end

    def get_similar_items_v2_callback(project_media, field)
      type = get_type(project_media)
      if !Bot::Alegre.should_get_similar_items_of_type?('master', project_media.team_id) || !Bot::Alegre.should_get_similar_items_of_type?(type, project_media.team_id)
        return {}
      else
        cached_data = get_cached_data(get_required_keys(project_media, field))
        if !cached_data.values.include?(nil)
          suggested_or_confirmed = cached_data[:suggested_or_confirmed_results]
          confirmed = cached_data[:confirmed_results]
          Bot::Alegre.merge_suggested_and_confirmed(suggested_or_confirmed, confirmed, project_media)
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
      self.add_relationships(project_media, self.get_similar_items_v2_callback(project_media, field)) unless project_media.is_blank?
    end

    def get_items_with_similar_media_v2(media_url, threshold, team_ids, type)
      alegre_path = ['audio', 'image'].include?(type) ? self.sync_path_for_type(type) : "/#{type}/similarity/search/"
      # FIXME: Stop using this method from v1 once all media types are supported by v2
      # FIXME: Alegre crashes if `media_url` was already requested before, this is why I append a hash
      self.get_items_with_similar_media("#{media_url}?hash=#{SecureRandom.hex}", threshold, team_ids, alegre_path)
    end

    def process_alegre_callback(params)
      redis = Redis.new(REDIS_CONFIG)
      project_media = ProjectMedia.find(params.dig('data', 'item', 'raw', 'context', 'project_media_id'))
      confirmed = params.dig('data', 'item', 'raw', 'confirmed')
      field = params.dig('data', 'item', 'raw', 'context', 'field')
      key = "alegre:async_results:#{project_media.id}_#{field}_#{confirmed}"
      response = Bot::Alegre.cache_items_via_callback(project_media, field, confirmed, params.dig('data', 'results', 'result'))
      redis.set(key, response.to_json)
      redis.expire(key, 1.day.to_i)
      Bot::Alegre.relate_project_media_callback(project_media, field)
    end
  end
end
