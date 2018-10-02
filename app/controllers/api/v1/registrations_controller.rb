class Api::V1::RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [:create]
  before_action :configure_account_update_params, only: [:update]

  respond_to :json

  include RegistrationsDoc

  # POST /resource
  def create
    # super
    build_resource(sign_up_params)

    begin
      User.current = resource
      resource.last_accepted_terms_at = Time.now
      resource.save!
      sign_up(resource_name, resource)
      render_success 'user', resource
    rescue ActiveRecord::RecordInvalid => e
      clean_up_passwords resource
      set_minimum_password_length
      render_error e.message.gsub(/^Validation failed: Email /, ''), 'INVALID_VALUE'
    end
  end

  # PUT /resource
  def update
    # super
    self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)

    resource_updated = update_resource(resource, account_update_params)
    User.current = resource

    if resource_updated
      sign_in resource, scope: resource_name, bypass_sign_in: true
      render_success 'user', resource
    else
      clean_up_passwords resource
      render_error 'Could not update user: ' + resource.errors.full_messages.join(', '), 'INVALID_VALUE'
    end
  end

  # DELETE /resource
  def destroy
    # super
    resource.destroy
    Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
    render_success
  end

  protected

  # If you have extra params to permit, append them to the sanitizer.
  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :login, :password, :password_confirmation, :image])
  end

  # If you have extra params to permit, append them to the sanitizer.
  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :password, :password_confirmation, :current_password])
  end
end
