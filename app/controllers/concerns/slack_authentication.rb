module SlackAuthentication
  extend ActiveSupport::Concern

  # OAuth callback
  def slack
    start_session_and_redirect(params[:destination])
  end
end
