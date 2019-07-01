class Api::V1::SessionsController < Devise::SessionsController
  before_action :configure_sign_in_params, only: [:create]

  include SessionsDoc

  # POST /resource/sign_in
  def create
    user = User.find_by pre_otp_params
    if user && user.otp_required_for_login
      render_error(I18n.t(:error_login_2fa), 'LOGIN_2FA_REQUIRED') and return
    end
    User.current = nil
    self.resource = warden.authenticate!(auth_options)
    sign_in(resource_name, resource)
    User.current = current_api_user
    destination = params[:destination]
    destination ? redirect_to(URI.parse(destination).path) : render_success('user', current_api_user)
  end

  # DELETE /resource/sign_out
  def destroy
    User.current = nil
    signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
    if signed_out
      destination = params[:destination]
      destination ? redirect_to(URI.parse(destination).path) : render_success
    else
      render_error('Could not logout', 'AUTH')
    end
  end

  private

  def pre_otp_params
    params.require(:api_user).permit(:email)
  end

  protected

  # If you have extra params to permit, append them to the sanitizer.
  def configure_sign_in_params
    devise_parameter_sanitizer.permit(:sign_in, keys: [:login, :password, :otp_attempt])
  end
end
