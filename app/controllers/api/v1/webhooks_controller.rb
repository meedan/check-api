module Api
  module V1
    class WebhooksController < BaseApiController
      skip_before_action :authenticate_from_token!

      def index
        bot_name_to_class = {
          smooch: Bot::Smooch,
          keep: Bot::Keep,
          fetch: Bot::Fetch
        }
        unless bot_name_to_class.has_key?(params[:name].to_sym)
          render_error('Bot not found', 'ID_NOT_FOUND', 404) and return
        end
        bot = bot_name_to_class[params[:name].to_sym]
        unless bot.valid_request?(request)
          render_error('Invalid request', 'UNKNOWN') and return
        end
        response = bot.webhook(request) if bot.respond_to?(:webhook)
        render_success 'success', response
      end
    end
  end
end
