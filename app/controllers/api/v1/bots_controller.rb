module Api
  module V1
    class BotsController < BaseApiController
      skip_before_filter :authenticate_from_token!

      BOT_NAME_TO_CLASS = {
        keep: Bot::Keep
      }

      def index
        if request.base_url != CONFIG['checkdesk_base_url_private']
          render_error('Not available for external calls', 'UNKNOWN') and return
        end
        unless BOT_NAME_TO_CLASS.has_key?(params[:name].to_sym)
          render_error('Bot not found', 'ID_NOT_FOUND', 404) and return
        end
        render_success 'data', BOT_NAME_TO_CLASS[params[:name].to_sym].run(request.body.read)
      end
    end
  end
end
