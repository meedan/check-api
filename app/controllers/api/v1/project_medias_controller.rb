module Api
  module V1
    class ProjectMediasController < BaseApiController
      skip_before_filter :authenticate_from_token!

      def oembed
        media = ProjectMedia.where(id: params[:id]).last
        if media.nil?
          render_error('Not found', 'ID_NOT_FOUND', 404)
        elsif media.project.team.private
          render_unauthorized
        else
          render json: media.as_oembed(params), status: 200
        end
      end
    end
  end
end
