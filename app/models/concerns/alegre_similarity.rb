require 'active_support/concern'

module AlegreSimilarity
  extend ActiveSupport::Concern

  module ClassMethods
    def translate_similar_items(similar_items, relationship_type)
      Hash[similar_items.collect{|k,v| [k, v.merge(relationship_type: relationship_type)]}]
    end

    def should_get_similar_items_of_type?(type, team_id)
      tbi = self.get_alegre_tbi(team_id)
      key = "#{type}_similarity_enabled"
      (!tbi || tbi.send("get_#{key}").nil?) ? (CheckConfig.get(key, true).to_s == 'true') : tbi.send("get_#{key}")
    end

    def get_similar_items(pm)
      Rails.logger.info "[Alegre Bot] [ProjectMedia ##{pm.id}] [Similarity 1/5] Getting similar items"
      type = Bot::Alegre.get_pm_type(pm)
      Rails.logger.info "[Alegre Bot] [ProjectMedia ##{pm.id}] [Similarity 2/5] Type is #{type.blank? ? "blank" : type}"
      unless type.blank?
        if !self.should_get_similar_items_of_type?('master', pm.team_id) || !self.should_get_similar_items_of_type?(type, pm.team_id)
          Rails.logger.info "[Alegre Bot] [ProjectMedia ##{pm.id}] [Similarity 3/5] ProjectMedia cannot be checked for similar items"
          return {}
        else
          Rails.logger.info "[Alegre Bot] [ProjectMedia ##{pm.id}] [Similarity 3/5] ProjectMedia can be checked for similar items"
        end
        suggested_or_confirmed = Bot::Alegre.get_items_with_similarity(type, pm, Bot::Alegre.get_threshold_for_query(type, pm))
        Rails.logger.info("[Alegre Bot] [ProjectMedia ##{pm.id}] [Similarity 4/5] suggested_or_confirmed for #{pm.id} is #{suggested_or_confirmed.inspect}")
        confirmed = Bot::Alegre.get_items_with_similarity(type, pm, Bot::Alegre.get_threshold_for_query(type, pm, true))
        Rails.logger.info("[Alegre Bot] [ProjectMedia ##{pm.id}] [Similarity 5/5] confirmed for #{pm.id} is #{confirmed.inspect}")
        Bot::Alegre.merge_suggested_and_confirmed(suggested_or_confirmed, confirmed, pm)
      else
        {}
      end
    end

    def get_items_with_similarity(type, pm, threshold, query_or_body = 'body')
      if type == 'text'
        self.get_merged_items_with_similar_text(pm, threshold)
      else
        results = self.get_items_with_similar_media(self.media_file_url(pm), threshold, pm.team_id, "/#{type}/similarity/", query_or_body).reject{ |id, _score_with_context| pm.id == id }
        self.merge_response_with_source_and_target_fields(results, type)
      end
    end

    def get_pm_type(pm)
      type = nil
      if pm.is_text?
        type = 'text'
      elsif pm.is_image?
        type = 'image'
      elsif pm.is_video?
        type = 'video'
      elsif pm.is_audio?
        type = 'audio'
      end
      return type
    end

    def get_pm_type_given_response(pm, response)
      base_type = self.get_pm_type(pm)
      specific_type = response[pm.id] && response[pm.id][:context] && response[pm.id][:context].class == Hash && response[pm.id][:context]["field"]
      if base_type == "text"
        raise if specific_type.nil?
        return specific_type || base_type
      elsif !base_type.nil?
        return base_type
      else
        return specific_type || base_type
      end
    end

    def get_target_field_map(response)
      project_media_type_map = Hash[ProjectMedia.where(id: response.keys).collect{|pm| [pm.id, self.get_pm_type_given_response(pm, response)]}]
      Hash[response.collect{|k,v| [k, v.merge(target_field: project_media_type_map[k])]}]
    end

    def merge_response_with_source_and_target_fields(response, source_field)
      self.get_target_field_map(Hash[response.collect{|k,v| [k, v.merge(source_field: source_field)]}])
    end

    def get_merged_items_with_similar_text(pm, threshold)
      by_title = self.merge_response_with_source_and_target_fields(self.get_items_with_similar_title(pm, threshold), "original_title")
      by_description = self.merge_response_with_source_and_target_fields(self.get_items_with_similar_description(pm, threshold), "original_description")
      Hash[(by_title.keys|by_description.keys).collect do |pmid|
        [pmid, [by_title[pmid], by_description[pmid]].compact.sort_by{|x| x[:score]}.last]
      end]
    end

    def relate_project_media_to_similar_items(pm)
      self.add_relationships(pm, self.get_similar_items(pm)) unless pm.is_blank?
    end

    def send_field_to_similarity_index(pm, field)
      value = pm.send(field) if !pm.nil? && pm.respond_to?(field)
      if value.blank?
        self.delete_field_from_text_similarity_index(pm, field, true)
      elsif value.size > 1
        self.send_to_text_similarity_index(pm, field, value, self.item_doc_id(pm, field))
      end
    end

    def delete_field_from_text_similarity_index(pm, field, quiet=false)
      self.delete_from_text_similarity_index(
        self.item_doc_id(pm, field),
        self.get_context(pm, field),
        quiet
      )
    end

    def delete_from_text_similarity_index(doc_id, context, quiet=false)
      self.request_api('delete', '/text/similarity/', {
        doc_id: doc_id,
        quiet: quiet
      })
    end

    def get_context(pm, field=nil)
      context = {
        team_id: pm.team_id,
        project_media_id: pm.id,
        has_custom_id: true
      }
      context[:field] = field if field
      context
    end

    def send_to_text_similarity_index_package(pm, field, text, doc_id, model=nil)
      model ||= self.indexing_model_to_use(pm)
      {
        doc_id: doc_id,
        text: text,
        model: model,
        context: self.get_context(pm, field)
      }
    end

    def send_to_text_similarity_index(pm, field, text, doc_id, model=nil)
      self.request_api(
        'post',
        '/text/similarity/',
        self.send_to_text_similarity_index_package(pm, field, text, doc_id, model)
      )
    end

    def delete_from_index(pm, fields=nil, quiet=false)
      if self.get_pm_type(pm) == "text"
        fields = ALL_TEXT_SIMILARITY_FIELDS if fields.nil?
        fields = fields.flatten.uniq
        fields.collect{|f| self.delete_field_from_text_similarity_index(pm, f, quiet)}
      else
        self.delete_from_media_similarity_index(pm)
      end
    end
    
    def delete_from_media_similarity_index(pm)
      unless self.get_pm_type(pm) == "text"
        params = {
          doc_id: self.item_doc_id(pm, type),
          url: self.media_file_url(pm),
          quiet: quiet
          context: self.get_context(pm),
        }
        self.request_api(
          'delete',
          "/#{type}/similarity/",
          params
        )
      end
    end

    def send_to_media_similarity_index(pm)
      unless self.get_pm_type(pm) == "text"
        params = {
          doc_id: self.item_doc_id(pm, type),
          url: self.media_file_url(pm),
          context: self.get_context(pm),
          match_across_content_types: true,
        }
        self.request_api(
          'post',
          "/#{type}/similarity/",
          params
        )
      end
    end

    def get_items_with_similar_title(pm, threshold)
      pm.original_title.blank? ? {} : self.get_merged_similar_items(pm, threshold, ['original_title', 'report_text_title', 'report_visual_card_title', 'fact_check_title'], pm.original_title)
    end

    def get_items_with_similar_description(pm, threshold, input_description = nil)
      description = input_description || pm.original_description
      description.blank? ? {} : self.get_merged_similar_items(pm, threshold, ['original_description', 'report_text_content', 'report_visual_card_content', 'extracted_text', 'transcription', 'claim_description_content', 'fact_check_summary'], description)
    end

    def get_merged_similar_items(pm, threshold, fields, value, team_ids = [pm&.team_id])
      output = {}
      fields.each do |field|
        response = self.get_items_with_similar_text(pm, field, threshold, value, [self.default_matching_model, self.matching_model_to_use(team_ids)].flatten.uniq, team_ids)
        output[field] = response unless response.blank?
      end
      es_matches = output.values.reduce({}, :merge)
      unless pm.nil?
        # Set matched fields to use in short-text suggestion
        pm.alegre_matched_fields ||= []
        pm.alegre_matched_fields.concat(output.keys)
      end
      es_matches
    end

    def get_similar_items_from_api(path, conditions, _threshold = {}, query_or_body = 'body')
      Rails.logger.error("[Alegre Bot] Sending request to alegre : #{path} , #{conditions.to_json}")
      response = {}
      result = self.request_api('get', path, conditions, query_or_body)&.dig('result')
      project_medias = result.collect{ |r| self.extract_project_medias_from_context(r) } if !result.nil? && result.is_a?(Array)
      project_medias.each do |request_response|
        request_response.each do |pmid, score_with_context|
          response[pmid] ||= score_with_context if self.should_include_id_in_result?(pmid, conditions)
        end
      end unless project_medias.nil?
      response.reject{ |id, _score_with_context| id.blank? }
    end

    def should_include_id_in_result?(pmid, conditions)
      team_id = conditions.dig(:context, :team_id)
      !team_id || [team_id].flatten.include?(ProjectMedia.find_by_id(pmid)&.team_id)
    end

    def get_items_with_similar_text(pm, field, threshold, text, models = nil, team_ids = [pm&.team_id])
      models ||= [self.matching_model_to_use(team_ids)].flatten
      self.get_items_from_similar_text(team_ids, text, field, threshold, models).reject{ |id, _score_with_context| pm&.id == id }
    end

    def similar_texts_from_api_conditions(text, models, fuzzy, team_id, field, threshold, match_across_content_types=true)
      {
        text: text,
        models: [models].flatten.empty? ? nil : [models].flatten.uniq,
        fuzzy: fuzzy == 'true' || fuzzy.to_i == 1,
        context: self.build_context(team_id, field),
        threshold: threshold[:value],
        match_across_content_types: match_across_content_types,
      }
    end

    def get_items_with_similar_media(media_url, threshold, team_id, path, query_or_body = 'body')
      self.get_similar_items_from_api(
        path,
        self.similar_media_content_from_api_conditions(
          team_id,
          media_url,
          threshold
        ),
        threshold,
        query_or_body
      )
    end

    def similar_media_content_from_api_conditions(team_id, media_url, threshold, match_across_content_types=true)
      {
        url: media_url,
        context: self.build_context(team_id),
        threshold: threshold[:value],
        match_across_content_types: match_across_content_types,
      }
    end
  end
end
