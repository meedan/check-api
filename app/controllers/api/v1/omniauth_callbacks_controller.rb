module Api
  module V1
    class OmniauthCallbacksController < Devise::OmniauthCallbacksController
      include TwitterAuthentication
      include FacebookAuthentication
      include SlackAuthentication

      def logout
        sign_out current_api_user
        User.current = nil
        destination = params[:destination] || '/'
        redirect_to destination
      end

      def failure
        redirect_to '/close.html'
      end

      protected

      def start_session_and_redirect
        auth = request.env['omniauth.auth']
        user = nil

        begin
          user = User.from_omniauth(auth)
        rescue ActiveRecord::RecordInvalid => e
          session['checkdesk.error'] = e.message
        end
        
        unless user.nil?
          session['checkdesk.current_user_id'] = user.id
          User.current = user
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
