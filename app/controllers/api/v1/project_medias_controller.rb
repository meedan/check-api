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
          unless @link.nil?
            response = { error: true }

            if @payload['screenshot_taken'].to_i == 1
              response = { screenshot_url: @payload['screenshot_url'], screenshot_taken: 1 }
              em = @link.pender_embed
              data = JSON.parse(em.data['embed'])
              data['screenshot_taken'] = 1
              em.embed = data.to_json
              em.save!
            end

            ProjectMedia.where(media_id: @link.id).each do |pm|
              next if pm.project.team.get_limits_keep_integration == false
              
              annotation = pm.annotations.where(annotation_type: 'pender_archive').last.load
              
              unless annotation.nil?
                annotation.skip_check_ability = true
                annotation.disable_es_callbacks = Rails.env.to_s == 'test'
                annotation.set_fields = { pender_archive_response: response.to_json }.to_json
                annotation.save!
              end
            end
          end
        end
        render_success
      end

      private

      def allow_iframe
        response.headers.except! 'X-Frame-Options'
      end
    end
  end
end
