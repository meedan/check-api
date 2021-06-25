module Api
  module V1
    class ProjectMediasController < BaseApiController
      skip_before_action :authenticate_from_token!
      after_action :allow_iframe, only: :oembed

      def oembed
        @options = params.merge({ from_pender: !request.headers['User-Agent'].to_s.match(/pender/i).nil? })
        media = ProjectMedia.where(id: params[:id]).last
        if media.nil?
          render_error('Not found', 'ID_NOT_FOUND', 404)
        else
          respond_to do |format|
            format.json { render(json: media.as_oembed(@options), status: 200) }
            format.html { render(html: media.html(@options), status: 200) }
          end
        end
      end

      private

      def allow_iframe
        response.headers.except! 'X-Frame-Options'
      end
    end
  end
end
