module FacebookAuthentication
  extend ActiveSupport::Concern

  # OAuth callback
  def facebook
    start_session_and_redirect
  end
end
