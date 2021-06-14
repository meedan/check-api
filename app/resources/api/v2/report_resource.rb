module Api
  module V2
    class ReportResource < BaseResource
      model_name 'ProjectMedia'

      attributes :title, :description, :lead_image, :archived, :created_at, :media_id
      attribute :workspace_id, delegate: :team_id
      attribute :report_title, delegate: :analysis_title
      attribute :report_body, delegate: :analysis_description
      attribute :article_link, delegate: :analysis_published_article_url
      attribute :report_rating, delegate: :status
      attribute :published, delegate: :analysis_published_date
      attribute :original_media, delegate: :uploaded_file_url
      attribute :original_claim_title, delegate: :original_title
      attribute :original_claim_body, delegate: :original_description
      attribute :original_claim_link, delegate: :link
      attribute :original_claim_author, delegate: :source_name
      attribute :similar_media, delegate: :linked_items_count
      attribute :requests, delegate: :requests_count
      attribute :check_url, delegate: :full_url
      attribute :organization, delegate: :team_name
      attribute :tags, delegate: :tags_as_sentence
      attribute :media_type, delegate: :type_of_media
      attribute :score
      attribute :report_image

      def score
        RequestStore.store[:scores] ? RequestStore.store[:scores][@model.id].to_f : nil
      end

      def self.records(options = {})
        teams = self.workspaces(options)
        team_ids = teams.map(&:id)
        conditions = { team_id: team_ids }
        if team_ids.size == Team.count
          team_ids = []
          conditions = {}
        end
        filters = options[:filters] || {}

        organization_ids = filters[:similarity_organization_ids].blank? ? team_ids : filters[:similarity_organization_ids].flatten.map(&:to_i)
        threshold = filters[:similarity_threshold] ? filters[:similarity_threshold].flatten[0].to_f : nil
        ids_text = self.apply_text_similarity_filter(organization_ids, threshold, filters)
        ids_image = self.apply_image_similarity_filter(organization_ids, threshold, filters)
        ids_video = self.apply_video_similarity_filter(organization_ids, threshold, filters)
        conditions[:id] = (ids_text.to_a + ids_image.to_a + ids_video.to_a).uniq if ids_text || ids_image || ids_video

        self.apply_check_filters(conditions, filters)
      end

      def self.apply_text_similarity_filter(organization_ids, threshold, filters)
        text = filters[:similar_to_text]
        ids = nil
        unless text.blank?
          fields = filters[:similarity_fields].blank? ? nil : filters[:similarity_fields].to_a.flatten
          ids_and_scores = Bot::Alegre.get_similar_texts(organization_ids, text[0], fields, {value: threshold}, nil, filters.dig(:fuzzy, 0))
          RequestStore.store[:scores] = ids_and_scores # Store the scores so we can return them
          ids = ids_and_scores.keys.uniq || [0]
        end
        ids
      end

      def self.apply_image_similarity_filter(organization_ids, threshold, filters)
        image = filters[:similar_to_image]
        ids = nil
        unless image.blank?
          image[0].rewind
          image_path = "api_v2_similar_image/#{SecureRandom.hex}"
          CheckS3.write(image_path, image[0].content_type, image[0].read)
          ids_and_scores = Bot::Alegre.get_similar_images(organization_ids, CheckS3.public_url(image_path), {value: threshold})
          RequestStore.store[:scores] = ids_and_scores # Store the scores so we can return them
          ids = ids_and_scores.keys.uniq || [0]
          CheckS3.delete(image_path)
        end
        ids
      end

      def self.apply_video_similarity_filter(organization_ids, threshold, filters)
        video = filters[:similar_to_video]
        ids = nil
        unless video.blank?
          video[0].rewind
          video_path = "api_v2_similar_video/#{SecureRandom.hex}"
          CheckS3.write(video_path, video[0].content_type, video[0].read)
          ids_and_scores = Bot::Alegre.get_similar_videos(organization_ids, CheckS3.public_url(video_path), {value: threshold})
          RequestStore.store[:scores] = ids_and_scores # Store the scores so we can return them
          ids = ids_and_scores.keys.uniq || [0]
          CheckS3.delete(video_path)
        end
        ids
      end

      def self.apply_check_filters(conditions, filters)
        new_conditions = conditions.clone
        result = ProjectMedia
        new_conditions[:archived] = filters[:archived] if filters.has_key?(:archived)
        result = result.joins(:media).where('medias.type' => filters[:media_type]) if filters.has_key?(:media_type)
        # FIXME: Not the best way to check for the report state
        if filters.has_key?(:report_state)
          value = filters[:report_state][0]
          if value == 'unpublished'
            result = result.joins("LEFT OUTER JOIN annotations a ON a.annotated_type = 'ProjectMedia' AND a.annotated_id = project_medias.id AND a.annotation_type = 'report_design'").where('a.annotated_id' => nil)
          else
            result = result.joins("INNER JOIN annotations a ON a.annotated_type = 'ProjectMedia' AND a.annotated_id = project_medias.id AND a.annotation_type = 'report_design'").where('a.data LIKE ?', "%state: #{value}%")
          end
        end
        result.where(new_conditions)
      end

      def self.count(filters, options = {})
        self.records(options.merge(filters: filters)).count
      end

      # Just declaring the filters used for similarity - the logic is above in the "records" method definition
      filter :report_state, apply: ->(records, _value, _options) { records } # 'paused' or 'published'
      filter :fuzzy, apply: ->(records, _value, _options) { records }
      filter :media_type, apply: ->(records, _value, _options) { records }
      filter :archived, apply: ->(records, _value, _options) { records }
      filter :similar_to_text, apply: ->(records, _value, _options) { records }
      filter :similar_to_image, apply: ->(records, _value, _options) { records }
      filter :similarity_fields, apply: ->(records, _value, _options) { records }
      filter :similarity_threshold, apply: ->(records, _value, _options) { records }
      filter :similarity_organization_ids, apply: ->(records, _value, _options) { records }
    end
  end
end
