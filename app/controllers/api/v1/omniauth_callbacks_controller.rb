module Api
  module V1
    class OmniauthCallbacksController < Devise::OmniauthCallbacksController
      include TwitterAuthentication
      include FacebookAuthentication
      include SlackAuthentication

      def logout
        sign_out current_api_user
        destination = params[:destination] || '/'
        redirect_to destination
      end

      protected

      def start_session_and_redirect
        auth = request.env['omniauth.auth']
        user = User.from_omniauth(auth)
        unless user.nil?
          session['checkdesk.current_user_id'] = user.id
          sign_in(user)
        end

        destination = params[:destination] || '/api'
        if request.env.has_key?('omniauth.params')
          destination = request.env['omniauth.params']['destination'] unless request.env['omniauth.params']['destination'].blank?
        end

        redirect_to destination
      end
    end
  end
end
