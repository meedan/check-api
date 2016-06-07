module FacebookAuthentication
  extend ActiveSupport::Concern

  included do
    skip_before_filter :authenticate_user_from_provider_token!, only: [:facebook]
  end

  # OAuth callback
  def facebook
    start_session_and_redirect('/api')
  end
end
