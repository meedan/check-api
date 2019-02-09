module Api
  module V1
    class BotsController < BaseApiController
      skip_before_filter :authenticate_from_token!

      BOT_NAME_TO_CLASS = {
        keep: Bot::Keep,
        smooch: Bot::Smooch,
        alegre: Bot::Alegre
      }

      def index
        unless BOT_NAME_TO_CLASS.has_key?(params[:name].to_sym)
          render_error('Bot not found', 'ID_NOT_FOUND', 404) and return
        end
        bot = BOT_NAME_TO_CLASS[params[:name].to_sym]
        unless bot.valid_request?(request)
          render_error('Invalid request', 'UNKNOWN') and return
        end
        render_success 'data', bot.run(request.body.read)
      end
    end
  end
end
