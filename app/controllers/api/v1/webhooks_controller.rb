module Api
  module V1
    class WebhooksController < BaseApiController
      skip_before_action :authenticate_from_token!

      def index
        bot_name_to_class = {
          smooch: Bot::Smooch,
          keep: Bot::Keep,
          fetch: Bot::Fetch,
          tagger: Bot::Tagger
        }
        unless bot_name_to_class.has_key?(params[:name].to_sym)
          render_error('Bot not found', 'ID_NOT_FOUND', 404) and return
        end
        bot = bot_name_to_class[params[:name].to_sym]
        unless bot.valid_request?(request)
          render_error('Invalid request', 'UNKNOWN') and return
        end

        begin
          response = bot&.webhook(request)
          render(plain: request.params['hub.challenge'], status: 200) and return if response == 'capi:verification'
        rescue Bot::Keep::ObjectNotReadyError => e
          render_error(e.message, 'OBJECT_NOT_READY', 425) and return
        end
        render_success 'success', response
      end
    end
  end
end
