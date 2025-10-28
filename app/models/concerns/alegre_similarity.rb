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
        if !Bot::Alegre.should_get_similar_items_of_type?('master', pm.team_id) || !Bot::Alegre.should_get_similar_items_of_type?(type, pm.team_id)
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

    def get_items_with_similarity(type, pm, threshold)
      if type == 'text'
        response = self.get_merged_items_with_similar_text(pm, threshold)
      else
        results = self.get_items_with_similar_media_v2(project_media: pm, team_ids: pm.team_id, type: type).reject{ |id, _score_with_context| pm.id == id }
        response = self.merge_response_with_source_and_target_fields(results, type)
      end
      self.restrict_contexts(pm, response)
    end

    def get_pm_type(pm)
      type = nil
      if pm.is_fact_check_imported?
        type = nil
      elsif pm.is_text?
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
      self.add_relationships(pm, self.get_similar_items(pm)) unless pm.is_fact_check_imported?
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
      self.request('delete', '/text/similarity/', {
        doc_id: doc_id,
        context: context,
        quiet: quiet
      })
    end

    def send_to_text_similarity_index_package(pm, field, text, doc_id)
      models ||= self.indexing_models_to_use(pm)
      language = self.language_for_similarity(pm&.team_id)
      params = {
        doc_id: doc_id,
        text: text,
        models: models,
        context: self.get_context(pm, field),
        requires_callback: true
      }
      params[:language] = language if !language.nil?
      params
    end

    def send_to_text_similarity_index(pm, field, text, doc_id)
      if !text.blank? && Bot::Alegre::BAD_TITLE_REGEX !~ text
        self.query_sync_with_params(
          self.send_to_text_similarity_index_package(pm, field, text, doc_id),
          "text"
        )
      end
    end

    def delete_from_index(pm, fields=nil, quiet=false)
      return if pm.nil?
      if self.get_pm_type(pm) == "text"
        fields = Bot::Alegre::ALL_TEXT_SIMILARITY_FIELDS if fields.nil?
        fields = fields.flatten.uniq
        fields.collect{|f| self.delete_field_from_text_similarity_index(pm, f, quiet)}
      else
        self.delete_from_media_similarity_index(pm, quiet)
      end
    end

    def delete_from_media_similarity_index(pm, quiet=false)
      type = self.get_pm_type(pm)
      unless type == "text"
        params = {
          doc_id: self.item_doc_id(pm, type),
          url: self.media_file_url(pm),
          quiet: quiet,
          context: self.get_context(pm),
        }
        self.request(
          'delete',
          "/#{type}/similarity/",
          params
        )
      end
    end

    def send_to_media_similarity_index(pm)
      type = self.get_pm_type(pm)
      if ['audio', 'video', 'image'].include?(type)
        params = {
          doc_id: self.item_doc_id(pm, type),
          url: self.media_file_url(pm),
          context: self.get_context(pm),
          match_across_content_types: true,
          requires_callback: true
        }
        self.request(
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
      output = self.get_items_with_similar_text(pm, fields, threshold, value, [self.default_matching_model, self.matching_model_to_use(team_ids)].flatten.uniq, team_ids)
      es_matches = output.reject{|_,v| v.blank?}
      unless pm.nil?
        # Set matched fields to use in short-text suggestion
        pm.alegre_matched_fields ||= []
        pm.alegre_matched_fields.concat(output.values.collect{|x| x[:context]["field"]})
      end
      es_matches
    end

    def get_similar_items_from_api(type, conditions, _threshold = {})
      Rails.logger.error("[Alegre Bot] Sending request to alegre : #{type} , #{conditions.to_json}")
      response = {}
      result = self.query_sync_with_params(conditions, type)&.dig('result')
      project_medias = result.collect{ |r| self.extract_project_medias_from_context(r) } if !result.nil? && result.is_a?(Array)
      project_medias.each do |request_response|
        request_response.each do |pmid, score_with_context|
          if self.should_include_id_in_result?(pmid, conditions)
            if response.include?(pmid)
              response[pmid].append(score_with_context)
            else
              response[pmid] = [score_with_context]
            end
          end
        end
      end unless project_medias.nil?
      self.get_similar_items_from_api_response(response)
    end

    def get_similar_items_from_api_response(response)
      response = response.reject{ |id, _score_with_context| id.blank? }
      # TODO: For now, this function will return one context per ProjectMedia
      # so that it does not change the previous spec
      collapsed_response = {}
      response.each do |pm, contexts|
        contexts = self.return_prioritized_matches(contexts)
        best_context = contexts.first
        # TODO: For images at least, context is an array.
        if contexts.count > 0 && (contexts[0].dig(:context)&.is_a?(Hash) || contexts[0].dig(:context).nil?)
          fields = contexts.collect{ |c| c.dig(:context, 'field') }
          models = contexts.collect{ |c| c[:model] }
          best_context[:context] ||= {}
          best_context[:context]['contexts_count'] = contexts.count
          best_context[:context]['field'] = fields.uniq.join('|')
          best_context[:model] = models.uniq.join('|')
          best_context[:model] = nil if best_context[:model].length == 0
        end
        collapsed_response[pm] = best_context
      end unless response.nil?
      collapsed_response
    end

    def should_include_id_in_result?(pmid, conditions)
      team_id = conditions.dig(:context, :team_id)
      !team_id || [team_id].flatten.include?(ProjectMedia.find_by_id(pmid)&.team_id)
    end

    def get_items_with_similar_text(pm, fields, threshold, text, models = nil, team_ids = [pm&.team_id])
      models ||= [self.matching_model_to_use(team_ids)].flatten
      self.get_items_from_similar_text(team_ids, text, fields, threshold, models).reject{ |id, _score_with_context| pm&.id == id }
    end

    def get_threshold_hash_from_threshold(threshold)
      threshold ||= []
      if threshold.length == 1
        { threshold: threshold[0]&.dig(:value) }
      else
        { per_model_threshold: Hash[threshold.collect{|t| [t[:model], t[:value]]}] }
      end
    end

    def get_min_es_score(team_id)
      self.get_alegre_tbi(team_id)&.get_min_es_score || Bot::Alegre::DEFAULT_ES_SCORE
    end

    def similar_texts_from_api_conditions(text, models, fuzzy, team_id, fields, threshold, match_across_content_types=true)
      params = {
        text: text,
        models: [models].flatten.empty? ? nil : [models].flatten.uniq,
        fuzzy: fuzzy == 'true' || fuzzy.to_i == 1,
        context: self.build_context(team_id, fields),
        match_across_content_types: match_across_content_types,
      }.merge(self.get_threshold_hash_from_threshold(threshold))
      language = self.language_for_similarity(team_id)
      params[:language] = language if !language.nil?
      params[:min_es_score] = self.get_min_es_score(team_id)
      params
    end

    def similar_media_content_from_api_conditions(team_id, media_url, threshold, match_across_content_types=true)
      {
        url: media_url,
        context: self.build_context(team_id),
        match_across_content_types: match_across_content_types,
      }.merge(self.get_threshold_hash_from_threshold(threshold))
    end
  end
end
