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
        session['check.' + auth.provider.to_s + '.authdata'] = { token: auth.credentials.token, secret: auth.credentials.secret }
        user = nil

        begin
          user = User.from_omniauth(auth, current_api_user)
        rescue ActiveRecord::RecordInvalid => e
          session['check.error'] = e.message
        rescue RuntimeError => e
          session['check.warning'] = e.message
        end

        unless user.nil?
          session['checkdesk.current_user_id'] = user.id
          User.current = user
          login_options = sign_in_options(user)
          sign_in(user, :bypass => login_options[:bypass]) if login_options[:login]
        end

        destination = get_check_destination

        redirect_to destination
      end

      def sign_in_options(user)
        login = { login: false, bypass: false }
        if current_api_user.nil?
          login[:login] = true
        else
          login = { login: true, bypass: true } if user.encrypted_password?
        end
        login
      end

      def get_check_destination
        destination = params[:destination] || '/api'
        if request.env.has_key?('omniauth.params')
          destination = request.env['omniauth.params']['destination'] unless request.env['omniauth.params']['destination'].blank?
        end
        destination
      end
    end
  end
end
