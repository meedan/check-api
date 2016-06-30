module TwitterAuthentication
  extend ActiveSupport::Concern

  # OAuth callback
  def twitter
    start_session_and_redirect(params[:destination])
  end
end
