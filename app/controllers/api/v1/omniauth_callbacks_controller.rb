module Api
  module V1
    class OmniauthCallbacksController < Devise::OmniauthCallbacksController
      include TwitterAuthentication
      include FacebookAuthentication

      protected

      def start_session_and_redirect(destination = '/')
        auth = request.env['omniauth.auth']
        user = User.from_omniauth(auth)
        unless user.nil?
          session['checkdesk.user'] = user.id
          sign_in(user)
        end
        redirect_to (destination || '/')
      end
    end
  end
end
