module Api
  module V1
    class OmniauthCallbacksController < Devise::OmniauthCallbacksController
      include FacebookAuthentication
      include SlackAuthentication
      include GoogleAuthentication

      before_action :store_request

      def logout
        sign_out current_api_user
        User.current = nil
        destination = params[:destination] || '/'
        redirect_to destination
      end

      def failure
        # To debug the error, call failure_message.inspect
        redirect_to '/close.html'
      end

      def setup
        setup_twitter if request.env['omniauth.strategy'].is_a?(OmniAuth::Strategies::Twitter)
        setup_facebook if request.env['omniauth.strategy'].is_a?(OmniAuth::Strategies::Facebook)
        render plain: 'Setup complete.', status: 404
      end

      private

      def store_request
        RequestStore[:request] = request
      end

      protected

      def start_session_and_redirect
        auth = request.env['omniauth.auth']
        session['check.' + auth.provider.to_s + '.authdata'] = { token: auth.credentials.token, secret: auth.credentials.secret }
        user = nil
        destination = get_check_destination

        # Don't start a new session if we're just authorizing an account to be used with the tipline
        unless destination =~ /smooch_bot/
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
            if login_options[:login]
              login_options[:bypass] ? bypass_sign_in(user) : sign_in(user)
            end
          end
        end

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
        destination = params[:destination] || '/close.html'
        if request.env.has_key?('omniauth.params')
          destination = request.env['omniauth.params']['destination'] unless request.env['omniauth.params']['destination'].blank?
        end
        destination
      end
    end
  end
end
