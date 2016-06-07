module TwitterAuthentication
  extend ActiveSupport::Concern

  included do
    skip_before_filter :authenticate_user_from_provider_token!, only: [:twitter]
  end

  # OAuth callback
  def twitter
    start_session_and_redirect(params[:destination])
  end
end
