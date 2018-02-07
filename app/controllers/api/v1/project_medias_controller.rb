module Api
  module V1
    class ProjectMediasController < BaseApiController
      skip_before_filter :authenticate_from_token!
      after_action :allow_iframe, only: :oembed
      before_filter :verify_payload!, only: :webhook

      def oembed
        @options = params.merge({ from_pender: !request.headers['User-Agent'].to_s.match(/pender/i).nil? })
        media = ProjectMedia.where(id: params[:id]).last
        if CONFIG['app_name'] != 'Check'
          render_error('Not implemented', 'UNKNOWN', 501)
        elsif media.nil?
          render_error('Not found', 'ID_NOT_FOUND', 404)
        else
          respond_to do |format|
            format.json { render(json: media.as_oembed(@options), status: 200) }
            format.html { render(html: media.html(@options), status: 200) }
          end
        end
      end

      def webhook
        if @payload['url'] 
          @link = Link.where(url: @payload['url']).last
          type = Bot::Keep.archiver_to_annotation_type(@payload['type'])
          unless @link.nil?
            response = Bot::Keep.set_response_based_on_pender_data(type, @payload) || { error: true }
            em = @link.pender_embed
            data = JSON.parse(em.data['embed'])
            data['archives'] ||= {}
            data['archives'][@payload['type']] = response
            response.each { |key, value| data[key] = value }
            em.embed = data.to_json
            em.save!

            ProjectMedia.where(media_id: @link.id).each do |pm|
              next if should_skip_project_media?(pm, type)
              
              annotation = pm.annotations.where(annotation_type: type).last
              
              unless annotation.nil?
                annotation = annotation.load
                annotation.skip_check_ability = true
                annotation.disable_es_callbacks = Rails.env.to_s == 'test'
                annotation.set_fields = { "#{type}_response" => response.to_json }.to_json
                annotation.save!
              end
            end
          end
        end
        render_success
      end

      protected

      def should_skip_project_media?(pm, type)
        archiver = Bot::Keep.annotation_type_to_archiver(type)
        pm.project.team.send("get_limits_keep_#{archiver}") == false || pm.project.team.send("get_archive_#{type}_enabled").to_i != 1 
      end

      private

      def allow_iframe
        response.headers.except! 'X-Frame-Options'
      end
    end
  end
end
