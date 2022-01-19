require 'active_support/concern'

module AlegreSimilarity
  extend ActiveSupport::Concern

  module ClassMethods
    def translate_similar_items(similar_items, relationship_type)
      Hash[similar_items.collect{|k,v| [k, {score: v, relationship_type: relationship_type}]}]
    end

    def should_get_similar_items_of_type?(type, team_id)
      tbi = self.get_alegre_tbi(team_id)
      key = "#{type}_similarity_enabled"
      (!tbi || tbi.send("get_#{key}").nil?) ? (CheckConfig.get(key, true).to_s == 'true') : tbi.send("get_#{key}")
    end

    def get_similar_items(pm)
      Rails.logger.info "[Alegre Bot] [ProjectMedia ##{pm.id}] [Similarity 1/5] Getting similar items"
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
      Rails.logger.info "[Alegre Bot] [ProjectMedia ##{pm.id}] [Similarity 2/5] Type is #{type.blank? ? "blank" : type}"
      unless type.blank?
        if !self.should_get_similar_items_of_type?('master', pm.team_id) || !self.should_get_similar_items_of_type?(type, pm.team_id)
          Rails.logger.info "[Alegre Bot] [ProjectMedia ##{pm.id}] [Similarity 3/5] ProjectMedia cannot be checked for similar items"
          return {}
        else
          Rails.logger.info "[Alegre Bot] [ProjectMedia ##{pm.id}] [Similarity 3/5] ProjectMedia can be checked for similar items"
        end
        suggested_or_confirmed = self.get_items_with_similarity(type, pm, self.get_threshold_for_query(type, pm))
        Rails.logger.info("[Alegre Bot] [ProjectMedia ##{pm.id}] [Similarity 4/5] suggested_or_confirmed for #{pm.id} is #{suggested_or_confirmed.inspect}")
        confirmed = self.get_items_with_similarity(type, pm, self.get_threshold_for_query(type, pm, true))
        Rails.logger.info("[Alegre Bot] [ProjectMedia ##{pm.id}] [Similarity 5/5] confirmed for #{pm.id} is #{confirmed.inspect}")
        self.merge_suggested_and_confirmed(suggested_or_confirmed, confirmed, pm)
      else
        {}
      end
    end

    def get_items_with_similarity(type, pm, threshold, query_or_body = 'body')
      if type == 'text'
        self.get_merged_items_with_similar_text(pm, threshold)
      else
        results = self.get_items_with_similar_media(self.media_file_url(pm), threshold, pm.team_id, "/#{type}/similarity/", query_or_body).reject{ |id, _score| pm.id == id }
        results
      end
    end

    def get_merged_items_with_similar_text(pm, threshold)
      by_title = self.get_items_with_similar_title(pm, threshold)
      by_description = self.get_items_with_similar_description(pm, threshold)
      Hash[(by_title.keys|by_description.keys).collect do |pmid|
        [pmid, [by_title[pmid].to_f, by_description[pmid].to_f].max]
      end]
    end

    def relate_project_media_to_similar_items(pm)
      self.add_relationships(pm, self.get_similar_items(pm)) unless pm.is_blank?
    end

    def send_field_to_similarity_index(pm, field)
      if pm.send(field).blank?
        self.delete_field_from_text_similarity_index(pm, field, true)
      else
        self.send_to_text_similarity_index(pm, field, pm.send(field), self.item_doc_id(pm, field))
      end
    end

    def delete_field_from_text_similarity_index(pm, field, quiet=false)
      self.delete_from_text_similarity_index(self.item_doc_id(pm, field), quiet)
    end

    def delete_from_text_similarity_index(doc_id, quiet=false)
      self.request_api('delete', '/text/similarity/', {
        doc_id: doc_id,
        quiet: quiet
      })
    end

    def send_to_text_similarity_index_package(pm, field, text, doc_id, model=nil)
      model ||= self.indexing_model_to_use(pm)
      {
        doc_id: doc_id,
        text: text,
        model: model,
        context: {
          team_id: pm.team_id,
          field: field,
          project_media_id: pm.id,
          has_custom_id: true
        }
      }
    end

    def send_to_text_similarity_index(pm, field, text, doc_id, model=nil)
      self.request_api(
        'post',
        '/text/similarity/',
        self.send_to_text_similarity_index_package(pm, field, text, doc_id, model)
      )
    end

    def send_to_media_similarity_index(pm)
      type = nil
      if pm.report_type == 'uploadedimage'
        type = 'image'
      elsif pm.report_type == 'uploadedvideo'
        type = 'video'
      elsif pm.report_type == 'uploadedaudio'
        type = 'audio'
      end
      unless type.blank?
        params = {
          doc_id: self.item_doc_id(pm, type),
          url: self.media_file_url(pm),
          context: {
            team_id: pm.team_id,
            project_media_id: pm.id,
            has_custom_id: true
          },
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
      pm.original_title.blank? ? {} : self.get_merged_similar_items(pm, threshold, ['original_title', 'report_text_title', 'report_visual_card_title'], pm.original_title)
    end

    def get_items_with_similar_description(pm, threshold, input_description = nil)
      description = input_description || pm.original_description
      description.blank? ? {} : self.get_merged_similar_items(pm, threshold, ['original_description', 'report_text_content', 'report_visual_card_content', 'extracted_text', 'transcription'], description)
    end

    def get_merged_similar_items(pm, threshold, fields, value)
      output = {}
      fields.each do |field|
        response = self.get_items_with_similar_text(pm, field, threshold, value, self.default_matching_model)
        output[field] = response unless response.blank?
      end

      if self.matching_model_to_use(pm) != self.default_matching_model
        fields.each do |field|
          response = self.get_items_with_similar_text(pm, field, threshold, value)
          output[field] = response unless response.blank?
        end
      end
      es_matches = output.values.reduce({}, :merge)
      # set matched fields to use in short-text suggestion
      pm.alegre_matched_fields ||= []
      pm.alegre_matched_fields.concat(output.keys)
      es_matches
    end

    def get_similar_items_from_api(path, conditions, _threshold={}, query_or_body = 'body' )
      Rails.logger.error("[Alegre Bot] Sending request to alegre : #{path} , #{conditions.to_json}")
      response = {}
      result = self.request_api('get', path, conditions, query_or_body)&.dig('result')
      project_medias = result.collect{ |r| self.extract_project_medias_from_context(r) } if !result.nil? && result.is_a?(Array)
      project_medias.each do |request_response|
        request_response.each do |pmid, score|
          response[pmid] = score
        end
      end unless project_medias.nil?
      response.reject{ |id, _score| id.blank? }
    end

    def get_items_with_similar_text(pm, field, threshold, text, model = nil)
      model ||= self.matching_model_to_use(pm)
      self.get_items_from_similar_text(pm.team_id, text, field, threshold, model).reject{ |id, _score| pm.id == id }
    end

    def similar_texts_from_api_conditions(text, model, fuzzy, team_id, field, threshold, match_across_content_types=true)
      {
        text: text,
        model: model,
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
