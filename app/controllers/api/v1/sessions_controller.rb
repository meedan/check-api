class Api::V1::SessionsController < Devise::SessionsController
  before_action :configure_sign_in_params, only: [:create]

  include SessionsDoc

  # POST /resource/sign_in
  def create
    User.current = nil
    self.resource = warden.authenticate!(auth_options)
    sign_in(resource_name, resource)
    User.current = current_api_user
    render_success 'user', current_api_user
  end

  # DELETE /resource/sign_out
  def destroy
    User.current = nil
    signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
    if signed_out
      destination = params[:destination]
      destination ? redirect_to(destination) : render_success
    else
      render_error('Could not logout', 'AUTH')
    end
  end

  protected

  # If you have extra params to permit, append them to the sanitizer.
  def configure_sign_in_params
    devise_parameter_sanitizer.permit(:sign_in, keys: [:login, :password])
  end
end
