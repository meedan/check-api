class AuthenticationController < ApplicationController
  include FacebookAuthentication

  def auth
    request.post? ? (set_auth and return) : (get_auth and return)
  end

  private

  def set_auth
    if signed_in?
      render(text: 'Authenticated')
    else
      token, id, provider, secret = get_custom_headers.values
      user = (token && id && provider) ? User.from_provider_token(provider, token, id, secret) : nil

      if user.nil?
        render(text: 'Unauthorized', status: 403)
      else
        sign_in(user)
        render(text: 'Authenticated')
      end
    end
  end

  def get_auth
    authenticated? || render(text: 'Authenticated')
  end
end
