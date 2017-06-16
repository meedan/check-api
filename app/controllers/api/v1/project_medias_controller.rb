module Api
  module V1
    class ProjectMediasController < BaseApiController
      skip_before_filter :authenticate_from_token!
      after_action :allow_iframe, only: :oembed

      def oembed
        media = ProjectMedia.where(id: params[:id]).last
        if CONFIG['app_name'] != 'Check'
          render_error('Not implemented', 'UNKNOWN', 501)
        elsif media.nil?
          render_error('Not found', 'ID_NOT_FOUND', 404)
        elsif media.project.team.private
          render_unauthorized
        else
          render json: media.as_oembed(params), status: 200
        end
      end

      private

      def allow_iframe
        response.headers.except! 'X-Frame-Options'
      end
    end
  end
end
